// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Flags {
  // TODO(johnniwinther): What is the right name for this?
  static const String nnbdStrongMode = "--nnbd-strong";
  static const String nnbdAgnosticMode = "--nnbd-agnostic";
  static const String nnbdWeakMode = "--nnbd-weak";

  static const String forceLateLowering = "--force-late-lowering";
  static const String forceLateLoweringSentinel =
      "--force-late-lowering-sentinel";
  static const String forceStaticFieldLowering =
      "--force-static-field-lowering";
  static const String forceNoExplicitGetterCalls =
      "--force-no-explicit-getter-calls";

  static const String target = "--target";

  static const String linkDependencies = "--link-dependencies";

  static const String compileSdk = "--compile-sdk";
  static const String dumpIr = "--dump-ir";
  static const String enableExperiment = "--enable-experiment";
  static const String excludeSource = "--exclude-source";
  static const String omitPlatform = "--omit-platform";
  static const String fatal = "--fatal";
  static const String fatalSkip = "--fatal-skip";
  static const String help = "--help";
  static const String librariesJson = "--libraries-json";
  static const String noDefines = "--no-defines";
  static const String noDeps = "--no-deps";
  static const String output = "--output";
  static const String packages = "--packages";
  static const String platform = "--platform";
  static const String sdk = "--sdk";
  static const String singleRootBase = "--single-root-base";
  static const String singleRootScheme = "--single-root-scheme";
  static const String verbose = "--verbose";
  static const String verify = "--verify";
  static const String verifySkipPlatform = "--verify-skip-platform";
  static const String warnOnReachabilityCheck = "--warn-on-reachability-check";
}
