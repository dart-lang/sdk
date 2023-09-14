// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'dart:io' show Directory, File;

import 'package:_fe_analyzer_shared/src/util/options.dart';
import 'package:front_end/src/api_prototype/compiler_options.dart'
    show parseExperimentalArguments, parseExperimentalFlags;
import 'package:front_end/src/api_prototype/experimental_flags.dart'
    show ExperimentalFlag;
import 'package:front_end/src/base/command_line_options.dart';
import 'package:testing/testing.dart' show TestDescription;

const Option<String?> overwriteCurrentSdkVersion =
    const Option('--overwrite-current-sdk-version', const StringValue());
const Option<bool> noVerifyCmd =
    const Option('--no-verify', const BoolValue(false));

const List<Option> folderOptionsSpecification = [
  Options.enableExperiment,
  Options.enableUnscheduledExperiments,
  Options.forceLateLoweringSentinel,
  overwriteCurrentSdkVersion,
  Options.forceLateLowering,
  Options.forceStaticFieldLowering,
  Options.forceNoExplicitGetterCalls,
  Options.forceConstructorTearOffLowering,
  Options.nnbdAgnosticMode,
  Options.noDefines,
  noVerifyCmd,
  Options.target,
  Options.defines,
  Options.showOffsets,
];

class SuiteFolderOptions {
  final Uri baseUri;
  final Map<Uri, FolderOptions> _folderOptions = {};

  SuiteFolderOptions(this.baseUri);

  FolderOptions _computeFolderOptions(Directory directory) {
    FolderOptions? folderOptions = _folderOptions[directory.uri];
    if (folderOptions == null) {
      bool? enableUnscheduledExperiments;
      int? forceLateLowering;
      bool? forceLateLoweringSentinel;
      bool? forceStaticFieldLowering;
      bool? forceNoExplicitGetterCalls;
      int? forceConstructorTearOffLowering;
      bool nnbdAgnosticMode = false;
      bool noVerify = false;
      Map<String, String>? defines = {};
      String target = "vm";
      bool showOffsets = false;
      if (directory.uri == baseUri) {
        folderOptions = new FolderOptions({},
            enableUnscheduledExperiments: enableUnscheduledExperiments,
            forceLateLowerings: forceLateLowering,
            forceLateLoweringSentinel: forceLateLoweringSentinel,
            forceStaticFieldLowering: forceStaticFieldLowering,
            forceNoExplicitGetterCalls: forceNoExplicitGetterCalls,
            forceConstructorTearOffLowering: forceConstructorTearOffLowering,
            nnbdAgnosticMode: nnbdAgnosticMode,
            defines: defines,
            noVerify: noVerify,
            target: target,
            showOffsets: showOffsets);
      } else {
        File optionsFile =
            new File.fromUri(directory.uri.resolve('folder.options'));
        if (optionsFile.existsSync()) {
          List<String> arguments =
              ParsedOptions.readOptionsFile(optionsFile.readAsStringSync());
          ParsedOptions parsedOptions =
              ParsedOptions.parse(arguments, folderOptionsSpecification);
          List<String> experimentalFlagsArguments =
              Options.enableExperiment.read(parsedOptions) ?? <String>[];
          String? overwriteCurrentSdkVersionArgument =
              overwriteCurrentSdkVersion.read(parsedOptions);
          enableUnscheduledExperiments =
              Options.enableUnscheduledExperiments.read(parsedOptions);
          forceLateLoweringSentinel =
              Options.forceLateLoweringSentinel.read(parsedOptions);
          forceLateLowering = Options.forceLateLowering.read(parsedOptions);
          forceStaticFieldLowering =
              Options.forceStaticFieldLowering.read(parsedOptions);
          forceNoExplicitGetterCalls =
              Options.forceNoExplicitGetterCalls.read(parsedOptions);
          forceConstructorTearOffLowering =
              Options.forceConstructorTearOffLowering.read(parsedOptions);
          nnbdAgnosticMode = Options.nnbdAgnosticMode.read(parsedOptions);
          defines = parsedOptions.defines;
          showOffsets = Options.showOffsets.read(parsedOptions);
          if (Options.noDefines.read(parsedOptions)) {
            if (defines.isNotEmpty) {
              throw "Can't have no defines and specific defines "
                  "at the same time.";
            }
            defines = null;
          }
          noVerify = noVerifyCmd.read(parsedOptions);
          target = Options.target.read(parsedOptions);
          folderOptions = new FolderOptions(
              parseExperimentalFlags(
                  parseExperimentalArguments(experimentalFlagsArguments),
                  onError: (String message) => throw new ArgumentError(message),
                  onWarning: (String message) =>
                      throw new ArgumentError(message)),
              enableUnscheduledExperiments: enableUnscheduledExperiments,
              forceLateLowerings: forceLateLowering,
              forceLateLoweringSentinel: forceLateLoweringSentinel,
              forceStaticFieldLowering: forceStaticFieldLowering,
              forceNoExplicitGetterCalls: forceNoExplicitGetterCalls,
              forceConstructorTearOffLowering: forceConstructorTearOffLowering,
              nnbdAgnosticMode: nnbdAgnosticMode,
              defines: defines,
              noVerify: noVerify,
              target: target,
              overwriteCurrentSdkVersion: overwriteCurrentSdkVersionArgument,
              showOffsets: showOffsets);
        } else {
          folderOptions = _computeFolderOptions(directory.parent);
        }
      }
      _folderOptions[directory.uri] = folderOptions;
    }
    return folderOptions;
  }

  FolderOptions computeFolderOptions(TestDescription description) {
    Directory directory = new File.fromUri(description.uri).parent;
    return _computeFolderOptions(directory);
  }

  static Map<ExperimentalFlag, bool> computeForcedExperimentalFlags(
      Map<String, String> environment) {
    Map<ExperimentalFlag, bool> experimentalFlags = <ExperimentalFlag, bool>{
      // Force enable features in development.
      ExperimentalFlag.records: true,
      ExperimentalFlag.patterns: true,
      ExperimentalFlag.sealedClass: true,
    };

    void addForcedExperimentalFlag(String name, ExperimentalFlag flag) {
      if (environment.containsKey(name)) {
        experimentalFlags[flag] = environment[name] == "true";
      }
    }

    addForcedExperimentalFlag(
        "enableExtensionMethods", ExperimentalFlag.extensionMethods);
    addForcedExperimentalFlag(
        "enableNonNullable", ExperimentalFlag.nonNullable);
    return experimentalFlags;
  }
}

/// Options used for all tests within a given folder.
///
/// This is used for instance for defining target, mode, and experiment specific
/// test folders.
class FolderOptions {
  final Map<ExperimentalFlag, bool> _explicitExperimentalFlags;
  final bool? enableUnscheduledExperiments;
  final int? forceLateLowerings;
  final bool? forceLateLoweringSentinel;
  final bool? forceStaticFieldLowering;
  final bool? forceNoExplicitGetterCalls;
  final int? forceConstructorTearOffLowering;
  final bool nnbdAgnosticMode;
  final Map<String, String>? defines;
  final bool noVerify;
  final String target;
  final String? overwriteCurrentSdkVersion;
  final bool showOffsets;

  FolderOptions(this._explicitExperimentalFlags,
      {this.enableUnscheduledExperiments,
      this.forceLateLowerings,
      this.forceLateLoweringSentinel,
      this.forceStaticFieldLowering,
      this.forceNoExplicitGetterCalls,
      this.forceConstructorTearOffLowering,
      this.nnbdAgnosticMode = false,
      this.defines = const {},
      this.noVerify = false,
      this.target = "vm",
      // can be null
      this.overwriteCurrentSdkVersion,
      this.showOffsets = false})
      : assert(
            // no this doesn't make any sense but left to underline
            // that this is allowed to be null!
            defines != null || defines == null);

  /// Computes the experimental flag for the folder.
  ///
  /// [forcedExperimentalFlags] is used to override the default flags the
  /// folder.
  Map<ExperimentalFlag, bool> computeExplicitExperimentalFlags(
      Map<ExperimentalFlag, bool> forcedExperimentalFlags) {
    Map<ExperimentalFlag, bool> flags = {};
    flags.addAll(_explicitExperimentalFlags);
    flags.addAll(forcedExperimentalFlags);
    return flags;
  }
}
