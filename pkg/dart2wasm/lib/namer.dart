// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'dynamic_module_kernel_metadata.dart' show MainModuleMetadata;
import 'js/util.dart' show JsInteropMemberData;
import 'translator.dart' show TranslatorOptions;
import 'util.dart';

/// Provides wasm import/export names for a module.
///
/// Each instance of [Namer] defines a namespace. Uniqueness is only guaranteed
/// within a namespace. Names passed to [getName] must themselves be unique for
/// a given namespace.
///
/// If [jsSafeNames] is true, the returned names will be safe to use as a
/// JavaScript identifier. This is useful if the name will be used as a key in a
/// JS object. Names only referenced from wasm modules can be any ASCII string.
///
/// Each name should appear exactly once in the wasm module (defining the
/// import/export) and JS code so we don't consider frequency when naming.
class Namer {
  final bool minify;
  final Set<String> _usedNames = {};
  int _nextId = 0;

  Namer({this.minify = false});

  /// Mark a name as reserved in case the name might collide with a
  /// pre-specified name such as an export.
  void reserveName(String name) {
    if (!minify) return;
    final added = _usedNames.add(name);
    assert(added, "Name '$name' is already reserved");
  }

  static String _jsSanitizeName(String name) {
    return name.replaceAll(RegExp(r'[^a-zA-Z0-9_$]'), '_');
  }

  /// Get an assigned name for the given name.
  ///

  String getName(String name, {bool jsSafeName = false}) {
    if (!minify) {
      String basename = name = jsSafeName ? _jsSanitizeName(name) : name;
      int counter = 0;
      while (!_usedNames.add(name)) {
        name = '${basename}_${counter++}';
      }
      return name;
    }
    do {
      name = jsSafeName
          ? intToMinJsSafeString(_nextId++)
          : intToMinString(_nextId++);
    } while (!_usedNames.add(name));
    return name;
  }
}

/// Manages naming for external interop members.
///
/// Members annotated with `@pragma('wasm:import', '...')` or
/// `@pragma('wasm:export', '...')` or `@pragma('wasm:weak-export', '...')`
/// are considered external members. These members are visible from outside the
/// Dart program and are therefore not minified. We do make sure that other
/// names do not collide with these names.
class _ExternalMemberNamer {
  final Namer _exportNamer;
  final CoreTypes coreTypes;

  _ExternalMemberNamer(this.coreTypes, this._exportNamer);
  ImportName? getImportName(Member member) {
    return getWasmImportPragma(coreTypes, member);
  }

  String? getExportName(Member member) {
    // External export names should be registered already so we don't have to
    // reserve them with the namer here.
    return getWasmExportPragma(coreTypes, member) ??
        getWasmWeakExportPragma(coreTypes, member);
  }

  bool registerExportName(Member member) {
    final name = getWasmExportPragma(coreTypes, member);
    if (name != null) {
      _exportNamer.reserveName(name);
      return true;
    }
    final weakName = getWasmWeakExportPragma(coreTypes, member);
    if (weakName != null) {
      _exportNamer.reserveName(weakName);
    }
    return false;
  }
}

/// Manages naming for internal interop helper members.
///
/// These members may import code from the support JS modules but are not
/// visible from outside the Dart program and are only used by the Dart runtime.
/// Their names can therefore be minified.
class _InteropHelperMemberNamer {
  final Namer _interopHelperNamer;
  final Namer _exportNamer;
  final CoreTypes coreTypes;
  final String interopModuleName;
  final MainModuleMetadata mainModuleMetadata;
  final Map<Member, String> interopMemberNames = {};

  _InteropHelperMemberNamer(
    this._exportNamer,
    this.coreTypes,
    this.mainModuleMetadata,
    TranslatorOptions options,
  ) : interopModuleName = options.minify ? '_' : 'dart2wasm',
      _interopHelperNamer = Namer(
        minify: options.minify || options.minifyInteropNames,
      );

  String get thisModuleSetterName =>
      mainModuleMetadata.thisModuleSetterExportName ??= _exportNamer.getName(
        '\$setThisModule',
        jsSafeName: true,
      );

  ImportName? getImportName(Member member) {
    final annotationInfo = JsInteropMemberData.fromMember(member, coreTypes);
    if (annotationInfo == null) return null;
    if (annotationInfo.isImport) {
      return ImportName(
        interopModuleName,
        interopMemberNames[member] ??= _interopHelperNamer.getName(
          member.name.text,
          jsSafeName: true,
        ),
      );
    }
    return null;
  }

  String? getExportName(Member member) {
    final annotationInfo = JsInteropMemberData.fromMember(member, coreTypes);
    if (annotationInfo == null) return null;
    if (annotationInfo.isWeakExport) {
      return interopMemberNames[member] ??= _exportNamer.getName(
        member.name.text,
        jsSafeName: true,
      );
    }
    return null;
  }
}

/// Manages naming for [Member]s associated with JS interop.
///
/// Some of these members are visible from JS outside of the Dart program and
/// are therefore not minified. Others are only helpers used by the Dart runtime
/// and can be minified.
class InteropMemberNamer {
  final _ExternalMemberNamer _externalMemberNamer;
  final _InteropHelperMemberNamer _interopHelperMemberNamer;

  InteropMemberNamer(
    CoreTypes coreTypes,
    Namer exportNamer,
    MainModuleMetadata mainModuleMetadata,
    TranslatorOptions options,
  ) : _externalMemberNamer = _ExternalMemberNamer(coreTypes, exportNamer),
      _interopHelperMemberNamer = _InteropHelperMemberNamer(
        exportNamer,
        coreTypes,
        mainModuleMetadata,
        options,
      );

  String get interopHelperModuleName =>
      _interopHelperMemberNamer.interopModuleName;
  String get thisModuleSetterName =>
      _interopHelperMemberNamer.thisModuleSetterName;

  /// Returns the import name for the given member.
  ///
  /// Returns null if the member is not an import. Checks both external and
  /// interop helper imports.
  ImportName? getImportName(Member member) {
    return _externalMemberNamer.getImportName(member) ??
        _interopHelperMemberNamer.getImportName(member);
  }

  /// Returns the export name for the given member.
  ///
  /// Returns null if the member is not an export. Checks both external and
  /// interop helper exports.
  String? getExportName(Member member) {
    final externalName = _externalMemberNamer.getExportName(member);
    if (externalName != null) return externalName;
    return _interopHelperMemberNamer.getExportName(member);
  }

  /// Registers the export name for the given member with the [Namer].
  ///
  /// Returns true if the member is a strong external export.
  bool registerExternalExportName(Member member) {
    return _externalMemberNamer.registerExportName(member);
  }
}
