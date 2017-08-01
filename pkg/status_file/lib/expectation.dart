// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// The possible outcomes from running a test.
class Expectation {
  /// The test completed normally and did what it intended to do.
  static final Expectation pass = new Expectation._('Pass');

  /// The process aborted in a way that is not a potential runtime error coming
  /// from the test itself. This is not considered a failure. It means an
  /// error happened so fundamental that success/failure could not be
  /// determined. Includes:
  ///
  /// * The Dart VM itself crashes, but not from an unhandled exception in user
  ///   code.
  ///
  /// * When running dart2js on top of the VM to compile some code, the VM
  ///   exits with a non-zero exit code or uncaught exception -- meaning an
  ///   internal exception in dart2js itself.
  ///
  /// * The browser process crashes.
  static final Expectation crash = new Expectation._('Crash');

  /// The test did not complete (either successfully or unsuccessfully) in the
  /// amount of time that the test runner gave it.
  static final Expectation timeout = new Expectation._('Timeout');

  /// The test completed but did not produce the intended output.
  ///
  /// This status is rarely used directly. Instead, most of the expectations
  /// below refine this into more specific reasons *why* it failed.
  static final Expectation fail = new Expectation._('Fail');

  /// The test compiled and began executing but then threw an uncaught
  /// exception or produced the wrong output.
  static final Expectation runtimeError =
      new Expectation._('RuntimeError', group: fail);

  /// The test failed with an error at compile time and did not execute any
  /// code.
  ///
  /// * For a VM test, means the VM exited with a "compile error" exit code 254.
  /// * For an analyzer test, means the analyzer reported a static error.
  /// * For a dart2js test, means dart2js reported a compile error.
  static final Expectation compileTimeError =
      new Expectation._('CompileTimeError', group: fail);

  /// The test itself contains a comment with `@runtime-error` in it,
  /// indicating it should have produced a runtime error when run. But when it
  /// was run, the test completed without error.
  static final Expectation missingRuntimeError =
      new Expectation._('MissingRuntimeError', group: fail);

  /// The test itself contains a comment with `@compile-error` in it,
  /// indicating it should have produced an error when compiled. But when it
  /// was compiled, no error was reported.
  static final Expectation missingCompileTimeError =
      new Expectation._('MissingCompileTimeError', group: fail);

  /// When the test is processed by analyzer, a static warning should be
  /// reported.
  static final Expectation staticWarning =
      new Expectation._('StaticWarning', group: fail);

  /// The test itself contains a comment with `@static-warning` in it,
  /// indicating analyzer should report a static warning when analyzing it, but
  /// analysis did not produce any warnings.
  static final Expectation missingStaticWarning =
      new Expectation._('MissingStaticWarning', group: fail);

  /// An invocation of "pub get" exited with a non-zero exit code.
  // TODO(rnystrom): Is this still used? If not, remove.
  static final Expectation pubGetError =
      new Expectation._('PubGetError', group: fail);

  /// The stdout or stderr produced by the test was not valid UTF-8 and could
  /// not be decoded.
  // TODO(rnystrom): The only test that uses this expectation is the one that
  // tests that the test runner handles this expectation. Remove it?
  static final Expectation nonUtf8Error =
      new Expectation._('NonUtf8Output', group: fail);

  /// The VM exited with the special exit code 252.
  static final Expectation dartkCrash =
      new Expectation._('DartkCrash', group: crash);

  /// A timeout occurred in a test using the Kernel-based front end.
  static final Expectation dartkTimeout =
      new Expectation._('DartkTimeout', group: timeout);

  /// A compile error was reported on a test compiled using the Kernel-based
  /// front end.
  static final Expectation dartkCompileTimeError =
      new Expectation._('DartkCompileTimeError', group: compileTimeError);

  // "meta expectations"
  /// A marker applied to a test to indicate that the other non-pass
  /// expectations are intentional and not a result of bugs or features that
  /// have yet to be implemented.
  ///
  /// For example, a test marked "RuntimeError, Ok" means "This test is
  /// *supposed* to fail at runtime."
  // TODO(rnystrom): This is redundant with other mechanisms like
  // `@runtime-error` and the markers in analyzer tests for stating where a
  // static error should be reported. It leads to perpetually larger status
  // files and means a reader of a test can't tell what the intended behavior
  // actually is without knowing which status files mention it. Remove.
  static final Expectation ok = new Expectation._('Ok', isMeta: true);

  /// A marker that indicates the test takes longer to complete than most tests.
  /// Tells the test runner to increase the timeout when running it.
  static final Expectation slow = new Expectation._('Slow', isMeta: true);

  /// Tells the test runner to not attempt to run the test.
  ///
  /// This means the test runner does not compare the test's actual results with
  /// the expected results at all. This expectation should be avoided since it's
  /// doesn't indicate *why* the test is being skipped and means we won't
  /// notice if the actual behavior of the test changes.
  static final Expectation skip = new Expectation._('Skip', isMeta: true);

  /// Tells the test runner to skip the test because it takes too long to
  /// complete.
  ///
  /// Prefer this over timeout since this avoids wasting CPU resources running
  /// a test we know won't complete.
  static final Expectation skipSlow =
      new Expectation._('SkipSlow', isMeta: true, group: skip);

  /// Skips this test because it is not intended to be meaningful for a certain
  /// reason or on some configuration.
  ///
  /// For example, tests that use dart:io are SkipByDesign on the browser since
  /// dart:io isn't supported there.
  static final Expectation skipByDesign =
      new Expectation._('SkipByDesign', isMeta: true);

  /// Can be returned by the test runner to say the result should be ignored,
  /// and assumed to meet the expectations, due to an infrastructure failure.
  ///
  /// This should not appear in status files.
  static final Expectation ignore = new Expectation._('Ignore');

  /// Used by pkg/front_end/lib/src/fasta/testing, but not used by test.dart.
  /// Included here so that we can parse .status files that contain it.
  static final Expectation verificationError =
      new Expectation._('VerificationError');

  /// Maps case-insensitive names to expectations.
  static Map<String, Expectation> _all = new Map.fromIterable(<Expectation>[
    pass,
    crash,
    timeout,
    fail,
    runtimeError,
    compileTimeError,
    missingRuntimeError,
    missingCompileTimeError,
    staticWarning,
    missingStaticWarning,
    pubGetError,
    nonUtf8Error,
    dartkCrash,
    dartkTimeout,
    dartkCompileTimeError,
    ok,
    slow,
    skip,
    skipSlow,
    skipByDesign,
    ignore,
    verificationError,
  ], key: (Expectation expectation) => expectation._name.toLowerCase());

  /// Looks up the expectation with [name].
  static Expectation find(String name) {
    var expectation = _all[name.toLowerCase()];
    if (expectation == null) {
      throw new ArgumentError("Could not find an expectation named '$name'.");
    }

    return expectation;
  }

  final String _name;
  final Expectation _group;

  /// Whether this expectation is a test outcome. If not, it's a "meta marker".
  final bool isOutcome;

  Expectation._(this._name, {Expectation group, bool isMeta: false})
      : _group = group,
        isOutcome = !isMeta;

  bool canBeOutcomeOf(Expectation expectation) {
    var outcome = this;
    if (outcome == ignore) return true;

    while (outcome != null) {
      if (outcome == expectation) {
        return true;
      }
      outcome = outcome._group;
    }

    return false;
  }

  String toString() => _name;
}
