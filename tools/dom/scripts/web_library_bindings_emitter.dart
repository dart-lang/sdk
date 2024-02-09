// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:io';

import 'package:_js_interop_checks/src/js_interop.dart';
import 'package:front_end/src/api_unstable/dart2js.dart';
import 'package:kernel/kernel.dart';

// Computes string maps that encode information about the bindings between the
// Dart types/members and their native JS equivalents.
void main(List<String> args) {
  if (args.length != 1) {
    print('usage: ${Platform.script} \$OUTPUT_FILE');
    return;
  }
  var component = loadComponentFromBinary(computePlatformBinariesLocation()
      .resolve('dart2js_platform.dill')
      .toFilePath());

  // We use `SplayTreeMap`s and `SplayTreeSet`s to retain the sorted order. This
  // is to ensure a deterministic order for the output file.
  final SplayTreeMap<String, SplayTreeMap<String, SplayTreeSet<String>>>
      nativeTypeToDartMembers =
      SplayTreeMap<String, SplayTreeMap<String, SplayTreeSet<String>>>();
  final SplayTreeMap<String, SplayTreeMap<String, String>>
      dartTypeToNativeMembers =
      SplayTreeMap<String, SplayTreeMap<String, String>>();
  final SplayTreeMap<String, SplayTreeSet<String>> dartTypeToNativeTypes =
      SplayTreeMap<String, SplayTreeSet<String>>();

  const Set<String> webLibraries = {
    'dart:html',
    'dart:indexed_db',
    'dart:svg',
    'dart:web_audio',
    'dart:web_gl'
  };

  const Set<String> duplicateClassNames = {
    'ImageElement',
    'ScriptElement',
    'StyleElement',
    'TitleElement'
  };

  for (var library in component.libraries) {
    if (webLibraries.contains(library.importUri.toString())) {
      for (var cls in library.classes) {
        if (cls.isMixinApplication) continue;
        // All strings in the maps are annotated with quotes, so that we print
        // proper Dart code when we print the maps.
        var clsName = "'${cls.name}'";
        var nativeTypes = getNativeNames(cls).map((name) => "'$name'").toList();
        if (nativeTypes.isEmpty) nativeTypes = [clsName];
        // There are a couple of cases where there are two classes with the same
        // name. They are all element classes bound to an `HTML` and an `SVG`
        // version. For now, ignore the `SVG` version, as they're unused in
        // google3 and most of them are marked unstable, and their `HTML`
        // variants are much more common.
        // TODO(srujzs): Remove this if we decide to deprecate these classes.
        if (duplicateClassNames.contains(cls.name)) {
          if (nativeTypes.length == 1 && nativeTypes[0] == "'SVG${cls.name}'") {
            continue;
          }
        }
        assert(!dartTypeToNativeTypes.containsKey(clsName));
        dartTypeToNativeTypes[clsName] = SplayTreeSet.from(nativeTypes);

        var nativePropToDartProp = SplayTreeMap<String, SplayTreeSet<String>>();
        var dartPropToNativeProp = SplayTreeMap<String, String>();

        for (var member in [
          ...cls.fields,
          // Ignore synthetic members.
          ...cls.procedures.where((procedure) => !procedure.isSynthetic),
          ...cls.constructors.where((constructor) => !constructor.isSynthetic),
        ]) {
          // Only record external members as they map to the native names.
          if (!member.isExternal) continue;
          // Private members can't be accessed.
          if (member.name.isPrivate) continue;
          var dartMember = "'${member.name}'";
          var nativeMember = "'${_getJSNameValue(member) ?? member.name.text}'";

          // Multiple `dart:html` members may be bound to the same native
          // symbol.
          nativePropToDartProp
              .putIfAbsent(nativeMember, () => SplayTreeSet<String>())
              .add(dartMember);
          for (var nativeType in nativeTypes) {
            nativeTypeToDartMembers[nativeType] = nativePropToDartProp;
          }

          dartPropToNativeProp[dartMember] = nativeMember;
          dartTypeToNativeMembers[clsName] = dartPropToNativeProp;
        }
      }
    }
  }
  var outputCode = """
    // A series of maps that record the various bindings we use in the web
    // libraries. The term bindings here can either refer to the value in an
    // `@Native` annotation or the value in a `@JSName` annotation. These maps
    // compute the relationship between those values and the Dart members they
    // annotate for fast lookup.

    /// Mapping of native types that are bound in the web libraries via
    /// `@Native` to a map of their members to those members' Dart names.
    final Map<String, Map<String, Set<String>>> nativeTypeToDartMembers = $nativeTypeToDartMembers;
    /// Mapping of `@Native` types in the web libraries to a map of their
    /// members to the native members that those members bind to.
    final Map<String, Map<String, String>> dartTypeToNativeMembers = $dartTypeToNativeMembers;
    /// Mapping of `@Native` types in the web libraries to the native types they
    /// bind.
    final Map<String, Set<String>> dartTypeToNativeTypes = $dartTypeToNativeTypes;
""";
  var outputFile = args[0];
  File(outputFile).writeAsStringSync(outputCode);
}

/// If [member] has a `@JSName('...')` annotation, returns the value inside the
/// parentheses.
///
/// If there is no value or the class does not have a `@JSName()` annotation,
/// returns null.
String? _getJSNameValue(Member member) {
  String? value;
  for (var annotation in member.annotations) {
    var c = annotationClass(annotation);
    if (c != null &&
        c.name == 'JSName' &&
        c.enclosingLibrary.importUri == Uri.parse('dart:_js_helper')) {
      var values = stringAnnotationValues(annotation);
      if (values.isNotEmpty) {
        value = values[0];
      }
    }
  }
  return value;
}
