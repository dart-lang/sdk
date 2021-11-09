// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/util/options.dart';
import 'package:front_end/src/api_prototype/compiler_options.dart';
import 'package:kernel/target/targets.dart';

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
  static const String forceConstructorTearOffLowering =
      "--force-constructor-tear-off-lowering";

  static const String target = "--target";

  static const String linkDependencies = "--link-dependencies";

  static const String compileSdk = "--compile-sdk";
  static const String dumpIr = "--dump-ir";
  static const String enableExperiment = "--enable-experiment";
  static const String enableUnscheduledExperiments =
      "--enable-unscheduled-experiments";
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
  static const String verbosity = "--verbosity";
  static const String verify = "--verify";
  static const String skipPlatformVerification = "--skip-platform-verification";
  static const String warnOnReachabilityCheck = "--warn-on-reachability-check";

  static const String invocationModes = "--invocation-modes";
}

class Options {
  static const Option<Uri?> compileSdk =
      const Option(Flags.compileSdk, const UriValue());
  static const Option<bool> dumpIr =
      const Option(Flags.dumpIr, const BoolValue(false));
  static const Option<List<String>?> enableExperiment =
      const Option(Flags.enableExperiment, const StringListValue());
  static const Option<bool> enableUnscheduledExperiments =
      const Option(Flags.enableUnscheduledExperiments, const BoolValue(false));
  static const Option<bool> excludeSource =
      const Option(Flags.excludeSource, const BoolValue(false));
  static const Option<bool> omitPlatform =
      const Option(Flags.omitPlatform, const BoolValue(false));
  static const Option<List<String>?> fatal =
      const Option(Flags.fatal, const StringListValue());
  static const Option<String?> fatalSkip =
      const Option(Flags.fatalSkip, const StringValue());
  static const Option<int?> forceLateLowering = const Option(
      Flags.forceLateLowering,
      const IntValue(defaultValue: null, noArgValue: LateLowering.all));
  static const Option<bool?> forceLateLoweringSentinel =
      const Option(Flags.forceLateLoweringSentinel, const BoolValue(null));
  static const Option<bool?> forceStaticFieldLowering =
      const Option(Flags.forceStaticFieldLowering, const BoolValue(null));
  static const Option<bool?> forceNoExplicitGetterCalls =
      const Option(Flags.forceNoExplicitGetterCalls, const BoolValue(null));
  static const Option<int?> forceConstructorTearOffLowering = const Option(
      Flags.forceConstructorTearOffLowering,
      const IntValue(
          defaultValue: null, noArgValue: ConstructorTearOffLowering.all));
  static const Option<bool> help = const Option(
      Flags.help, const BoolValue(false),
      aliases: ["-h", "/?", "/h"]);
  static const Option<Uri?> librariesJson =
      const Option(Flags.librariesJson, const UriValue());
  static const Option<bool> noDefines =
      const Option(Flags.noDefines, const BoolValue(false));
  static const Option<Uri?> output =
      const Option(Flags.output, const UriValue(), aliases: ["--out", "-o"]);
  static const Option<Uri?> packages =
      const Option(Flags.packages, const UriValue());
  static const Option<Uri?> platform =
      const Option(Flags.platform, const UriValue());
  static const Option<Uri?> sdk = const Option(Flags.sdk, const UriValue());
  static const Option<Uri?> singleRootBase =
      const Option(Flags.singleRootBase, const UriValue());
  static const Option<String?> singleRootScheme =
      const Option(Flags.singleRootScheme, const StringValue());
  static const Option<bool> nnbdWeakMode =
      const Option(Flags.nnbdWeakMode, const BoolValue(false));
  static const Option<bool> nnbdStrongMode =
      const Option(Flags.nnbdStrongMode, const BoolValue(false));
  static const Option<bool> nnbdAgnosticMode =
      const Option(Flags.nnbdAgnosticMode, const BoolValue(false));
  static const Option<String> target = const Option(
      Flags.target, const StringValue(defaultValue: 'vm'),
      aliases: ["-t"]);
  static const Option<bool> verbose =
      const Option(Flags.verbose, const BoolValue(false), aliases: ["-v"]);
  static const Option<String> verbosity = const Option(
      Flags.verbosity, const StringValue(defaultValue: Verbosity.defaultValue));
  static const Option<bool> verify =
      const Option(Flags.verify, const BoolValue(false));
  static const Option<bool> skipPlatformVerification =
      const Option(Flags.skipPlatformVerification, const BoolValue(false));
  static const Option<bool> warnOnReachabilityCheck =
      const Option(Flags.warnOnReachabilityCheck, const BoolValue(false));
  static const Option<List<Uri>?> linkDependencies =
      const Option(Flags.linkDependencies, const UriListValue());
  static const Option<bool> noDeps =
      const Option(Flags.noDeps, const BoolValue(false));
  static const Option<String?> invocationModes =
      const Option(Flags.invocationModes, const StringValue());
  static const Option<Map<String, String>> defines = const Option(
      "-D", const DefineValue(),
      isDefines: true, aliases: ["--define"]);
}
