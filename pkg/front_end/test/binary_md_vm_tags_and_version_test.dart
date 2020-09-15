// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show File, Platform;

import 'package:_fe_analyzer_shared/src/messages/severity.dart' show Severity;

import 'package:front_end/src/api_prototype/compiler_options.dart'
    show DiagnosticMessage;

import 'package:kernel/kernel.dart'
    show Class, Component, ConstantExpression, Field, IntConstant, Library;

import 'package:kernel/target/targets.dart' show NoneTarget, TargetFlags;

import 'binary_md_dill_reader.dart' show BinaryMdDillReader;

import 'incremental_load_from_dill_suite.dart'
    show getOptions, normalCompileToComponent;

import 'utils/io_utils.dart' show computeRepoDir;

const String maxSupported =
    "static const uint32_t kMaxSupportedKernelFormatVersion = ";

// Match stuff like "V(Nothing, 0)"
final RegExp tagParser = new RegExp(r"V\((\w*),\s*(\d+)\)");

// Match stuff like "kNullConstant = 0,"
final RegExp constantTagParser = new RegExp(r"k(\w*)\s*=\s*(\d+)");

main() async {
  File binaryMd = new File("$repoDir/pkg/kernel/binary.md");
  String binaryMdContent = binaryMd.readAsStringSync();

  BinaryMdDillReader binaryMdReader =
      new BinaryMdDillReader(binaryMdContent, []);
  binaryMdReader.setup();

  File vmTagFile = new File("$repoDir/runtime/vm/kernel_binary.h");
  String vmTagContent = vmTagFile.readAsStringSync();
  List<String> vmTagLines = vmTagContent.split("\n");
  int vmVersion;
  Map<int, String> vmTagToName = {};
  Map<int, String> vmConstantTagToName = {};
  for (int i = 0; i < vmTagLines.length; i++) {
    String line = vmTagLines[i];
    if (line.startsWith(maxSupported)) {
      vmVersion = int.parse(line
          .substring(line.indexOf(maxSupported) + maxSupported.length)
          .substring(0, 2) // Assume version < 100 for now.
          .trim());
    } else if (line.startsWith("#define KERNEL_TAG_LIST(V)")) {
      while (true) {
        RegExpMatch match = tagParser.firstMatch(line);
        if (match != null) {
          int value = int.parse(match.group(2));
          int end = value + 1;
          if (uses8Tags(match.group(1))) {
            end = value + 8;
          }
          for (int j = value; j < end; j++) {
            vmTagToName[j] = match.group(1);
          }
        }
        if (!vmTagLines[i].trim().endsWith(r"\")) {
          break;
        }
        i++;
        line = vmTagLines[i];
      }
    } else if (line.startsWith("enum ConstantTag {")) {
      while (true) {
        RegExpMatch match = constantTagParser.firstMatch(line);
        if (match != null) {
          vmConstantTagToName[int.parse(match.group(2))] = match.group(1);
        }
        if (vmTagLines[i].trim().startsWith("}")) {
          break;
        }
        i++;
        line = vmTagLines[i];
      }
    }
  }

  final Uri kernelTagUri = Uri.base.resolve("pkg/kernel/lib/binary/tag.dart");
  Component c = await normalCompileToComponent(kernelTagUri,
      options: getOptions()
        ..target = new NoneTarget(new TargetFlags())
        ..onDiagnostic = (DiagnosticMessage message) {
          if (message.severity == Severity.error) {
            print(message.plainTextFormatted.join('\n'));
          }
        });

  Library tagLibrary =
      c.libraries.firstWhere((l) => l.fileUri.pathSegments.last == "tag.dart");
  Class tagClass = tagLibrary.classes.firstWhere((c) => c.name == "Tag");
  Class constantTagClass =
      tagLibrary.classes.firstWhere((c) => c.name == "ConstantTag");

  int tagVersion;
  for (TagCompare compareMe in [
    new TagCompare(binaryMdReader.tagToName, binaryMdReader.version,
        vmTagToName, vmVersion, tagClass),
    new TagCompare(binaryMdReader.constantTagToName, binaryMdReader.version,
        vmConstantTagToName, vmVersion, constantTagClass)
  ]) {
    Map<int, String> tagToName = {};
    for (Field f in compareMe.tagClass.fields) {
      // Class doesn't only contain tag stuff.
      if (f.name.text.endsWith("Mask")) continue;
      if (f.name.text.endsWith("HighBit")) continue;
      if (f.name.text.endsWith("Bias")) continue;
      if (f.name.text == "ComponentFile") continue;
      ConstantExpression value = f.initializer;
      IntConstant intConstant = value.constant;
      int intValue = intConstant.value;
      if (f.name.text == "BinaryFormatVersion") {
        tagVersion = intValue;
        continue;
      }

      int end = intValue + 1;
      // There are a few special cases that takes up a total of 8 tags.
      if (uses8Tags(f.name.text)) {
        end = intValue + 8;
      }
      for (; intValue < end; intValue++) {
        if (tagToName[intValue] != null) {
          throw "Double entry for ${intValue}: "
              "${f.name.text} and ${tagToName[intValue]}";
        }
        tagToName[intValue] = f.name.text;
      }
    }

    Map<int, String> tagToNameMd = {};
    for (MapEntry<int, String> entry in compareMe.mdTagToName.entries) {
      if (entry.value.contains("<")) {
        tagToNameMd[entry.key] =
            entry.value.substring(0, entry.value.indexOf("<")).trim();
      } else {
        tagToNameMd[entry.key] = entry.value;
      }
    }

    // Kernels tag.dart vs binary.mds tags.
    for (int key in tagToNameMd.keys) {
      String nameMd = tagToNameMd[key];
      String name = tagToName[key];
      if (nameMd == name) continue;
      throw "$key: $nameMd vs $name";
    }
    for (int key in tagToName.keys) {
      String nameMd = tagToNameMd[key];
      String name = tagToName[key];
      if (nameMd == name) continue;
      throw "$key: $nameMd vs $name";
    }
    if (tagVersion != compareMe.mdVersion) {
      throw "Version in tag.dart: $tagVersion; "
          "version in binary.md: ${compareMe.mdVersion}";
    }

    // Kernels tag.dart vs the VMs tags.
    // Here we only compare one way because the VM can have more (old) tags.
    for (int key in tagToName.keys) {
      String nameVm = compareMe.vmTagToName[key];
      String name = tagToName[key];
      if (nameVm == name) continue;
      throw "$key: $nameVm vs $name";
    }
    if (tagVersion != compareMe.vmVersion) {
      throw "Version in tag.dart: $tagVersion; "
          "version in VM: ${compareMe.vmVersion}";
    }
  }

  print("OK");
}

bool uses8Tags(String name) {
  return name == "SpecializedVariableGet" ||
      name == "SpecializedVariableSet" ||
      name == "SpecializedIntLiteral";
}

final String repoDir = computeRepoDir();

String get dartVm => Platform.executable;

class TagCompare {
  final Map<int, String> mdTagToName;
  final int mdVersion;
  final Map<int, String> vmTagToName;
  final int vmVersion;
  final Class tagClass;

  TagCompare(this.mdTagToName, this.mdVersion, this.vmTagToName, this.vmVersion,
      this.tagClass);
}
