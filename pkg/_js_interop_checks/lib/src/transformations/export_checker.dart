// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: implementation_imports

import 'package:_fe_analyzer_shared/src/messages/codes.dart'
    show
        templateJsInteropExportDartInterfaceHasNonEmptyJSExportValue,
        templateJsInteropExportDisallowedMember,
        templateJsInteropExportMemberCollision,
        templateJsInteropExportNoExportableMembers;
import 'package:_js_interop_checks/js_interop_checks.dart'
    show JsInteropDiagnosticReporter;
import 'package:_js_interop_checks/src/js_interop.dart' as js_interop;
import 'package:kernel/ast.dart';

enum ExportStatus {
  exportError,
  exportable,
  nonExportable,
}

class GetSet {
  Member? getter;
  Member? setter;

  GetSet(this.getter, this.setter);
}

class ExportChecker {
  final JsInteropDiagnosticReporter _diagnosticReporter;
  final Map<Reference, Map<String, Set<Member>>> exportClassToMemberMap = {};
  final Map<Reference, ExportStatus> exportStatus = {};
  final Class _objectClass;
  final Map<Reference, Map<String, Member>> _overrideMap = {};
  // Store map of libraries to @staticInterop extensions, so that we can compute
  // the class to extension map later. Prefer to do it this way so that modular
  // compilation can invalidate recompiled extensions.
  static final Map<Reference, Set<Extension>> libraryExtensionMap = {};

  ExportChecker(this._diagnosticReporter, this._objectClass);

  /// Gets the getter and setter from the given [exports].
  ///
  /// [exports] should be a set of members from the [exportClassToMemberMap]. If
  /// missing a getter and/or setter, the corresponding field will be `null`.
  GetSet getGetterSetter(Set<Member> exports) {
    assert(exports.isNotEmpty && exports.length <= 2);
    Member? getter;
    Member? setter;

    var firstExport = exports.first;
    if (exports.length == 1) {
      if (firstExport.isGetter) {
        getter = firstExport;
      }
      if (firstExport.isSetter) {
        setter = firstExport;
      }
    } else if (exports.length == 2) {
      var secondExport = exports.elementAt(1);
      // One of them could be a partially overridden non-final field, so
      // determine the strict getter or setter first.
      if (firstExport.isStrictGetter || secondExport.isStrictSetter) {
        getter = firstExport;
        setter = secondExport;
      } else {
        getter = secondExport;
        setter = firstExport;
      }
    }

    return GetSet(getter, setter);
  }

  /// Calculates the overrides, including inheritance, for [cls].
  ///
  /// Note that we use a map from the unique name (with setter renaming) to
  /// avoid duplicate checks on classes, and to store the overrides.
  void _collectOverrides(Class cls) {
    if (_overrideMap.containsKey(cls.reference)) return;
    Map<String, Member> memberMap;
    var superclass = cls.superclass;
    if (superclass != null && superclass != _objectClass) {
      _collectOverrides(superclass);
      memberMap = Map.from(_overrideMap[superclass.reference]!);
    } else {
      memberMap = {};
    }
    // If this is a mixin application, fetch the members from the mixin.
    var demangledCls = cls.isMixinApplication ? cls.mixin : cls;
    for (var member in [
      ...demangledCls.procedures.where((proc) => proc.exportable),
      ...demangledCls.fields.where((field) => field.exportable)
    ]) {
      var memberName = member.name.text;
      if (member is Procedure && member.isSetter) {
        memberMap['$memberName='] = member;
      } else {
        if (member is Field && !member.isFinal) {
          memberMap['$memberName='] = member;
        }
        memberMap[memberName] = member;
      }
    }
    _overrideMap[cls.reference] = memberMap;
  }

  /// Determine if [cls] is exportable, and if so, compute the export members.
  ///
  ///
  /// Check the following:
  /// - If the class has a `@JSExport` annotation, the value should be empty.
  /// - If the class has the annotation, it should have at least one exportable
  /// member in the class or in any superclass (ignoring `Object`).
  /// - Accounting for Dart overrides, the export member map of the class or
  /// any of its superclasses do not contain unresolvable name collisions. An
  /// explanation of the resolvable collisions is below.
  void visitClass(Class cls) {
    var classHasJSExport = js_interop.hasJSExportAnnotation(cls);
    // If the class doesn't have the annotation or if the class wasn't marked
    // when we visited the members and checked their annotations, there's
    // nothing to do for this class.
    if (!classHasJSExport &&
        exportStatus[cls.reference] != ExportStatus.exportable) {
      exportStatus[cls.reference] = ExportStatus.nonExportable;
      return;
    }

    if (classHasJSExport && js_interop.getJSExportName(cls).isNotEmpty) {
      _diagnosticReporter.report(
          templateJsInteropExportDartInterfaceHasNonEmptyJSExportValue
              .withArguments(cls.name),
          cls.fileOffset,
          cls.name.length,
          cls.location?.file);
      exportStatus[cls.reference] = ExportStatus.exportError;
    }

    _collectOverrides(cls);

    var allExportableMembers = _overrideMap[cls.reference]!.values.where(
        (member) =>
            // Only members that qualify are those that are exportable, and
            // either their class has the annotation or they have it themselves.
            member.exportable &&
            (js_interop.hasJSExportAnnotation(member) ||
                js_interop.hasJSExportAnnotation(member.enclosingClass!)));
    var exports = <String, Set<Member>>{};

    // Store the exportable members.
    for (var member in allExportableMembers) {
      var exportName = member.exportPropertyName;
      exports.putIfAbsent(exportName, () => {}).add(member);
    }

    // Walk through the export map and determine if there are any unresolvable
    // conflicts.
    for (var exportName in exports.keys) {
      var existingMembers = exports[exportName]!;
      if (existingMembers.length == 1) continue;
      if (existingMembers.length == 2) {
        // There are two instances where you can resolve collisions:
        // 1. One of the members is a non-final field, and the other one is
        // either a strict getter or a strict setter that overrides part of
        // that field.
        // 2. One of the members is a strict getter, and the other one is a
        // strict setter or vice versa.
        // Any other case is an error to have more than 1 member per name.
        bool isCollisionOkay(Member m1, Member m2) {
          if (m1.isNonFinalField &&
              (m2.isStrictGetter || m2.isStrictSetter) &&
              // Is an override if the same name and across different classes.
              (m1.name.text == m2.name.text &&
                  m1.enclosingClass != m2.enclosingClass)) {
            return true;
          } else if (m1.isStrictGetter && m2.isStrictSetter) {
            return true;
          }
          return false;
        }

        var first = existingMembers.elementAt(0);
        var second = existingMembers.elementAt(1);
        if (isCollisionOkay(first, second) || isCollisionOkay(second, first)) {
          continue;
        }
      }
      // Sort to get deterministic order.
      var sortedExistingMembers =
          existingMembers.map((member) => member.toString()).toList()..sort();
      _diagnosticReporter.report(
          templateJsInteropExportMemberCollision.withArguments(
              exportName, sortedExistingMembers.join(', ')),
          cls.fileOffset,
          cls.name.length,
          cls.location?.file);
      exportStatus[cls.reference] = ExportStatus.exportError;
    }

    if (exports.isEmpty) {
      _diagnosticReporter.report(
          templateJsInteropExportNoExportableMembers.withArguments(cls.name),
          cls.fileOffset,
          cls.name.length,
          cls.location?.file);
      exportStatus[cls.reference] = ExportStatus.exportError;
    }

    exportClassToMemberMap[cls.reference] = exports;
    exportStatus[cls.reference] ??= ExportStatus.exportable;
  }

  /// Check that the [member] can be exportable if it has an annotation, and if
  /// so, mark the enclosing class as exportable.
  void visitMember(Member member) {
    var memberHasJSExportAnnotation = js_interop.hasJSExportAnnotation(member);
    var cls = member.enclosingClass;
    if (memberHasJSExportAnnotation) {
      if (!member.exportable) {
        _diagnosticReporter.report(
            templateJsInteropExportDisallowedMember
                .withArguments(member.name.text),
            member.fileOffset,
            member.name.text.length,
            member.location?.file);
        if (cls != null) {
          exportStatus[cls.reference] = ExportStatus.exportError;
        }
      } else {
        // Mark as exportable so we know that the class has an exportable member
        // when we process the class later.
        if (cls != null) exportStatus[cls.reference] = ExportStatus.exportable;
      }
    }
  }

  void visitLibrary(Library library) {
    for (var extension in library.extensions) {
      var onType = extension.onType;
      if (onType is InterfaceType &&
          js_interop.hasStaticInteropAnnotation(onType.classNode)) {
        libraryExtensionMap
            .putIfAbsent(library.reference, () => {})
            .add(extension);
      }
    }
  }
}

extension ExtensionMemberDescriptorExtension on ExtensionMemberDescriptor {
  bool get isGetter => kind == ExtensionMemberKind.Getter;
  bool get isSetter => kind == ExtensionMemberKind.Setter;
  bool get isMethod => kind == ExtensionMemberKind.Method;

  bool get isExternal => (memberReference.asProcedure).isExternal;
}

extension ProcedureExtension on Procedure {
  // We only care about concrete instance procedures that don't define their own
  // type parameters.
  bool get exportable =>
      !isAbstract &&
      !isStatic &&
      !isExtensionMember &&
      !isFactory &&
      !isExternal &&
      function.typeParameters.isEmpty &&
      kind != ProcedureKind.Operator;
}

extension FieldExtension on Field {
  // We only care about concrete instance fields.
  bool get exportable => !isAbstract && !isStatic && !isExternal;
}

extension MemberExtension on Member {
  // Get the property name that this member will be exported as.
  String get exportPropertyName {
    var rename = js_interop.getJSExportName(this);
    return rename.isEmpty ? name.text : rename;
  }

  bool get exportable =>
      (this is Procedure && (this as Procedure).exportable) ||
      (this is Field && (this as Field).exportable);

  // Only a getter and not a setter.
  bool get isStrictGetter =>
      (this is Procedure && (this as Procedure).isGetter) ||
      (this is Field && (this as Field).isFinal);

  // Only a setter and not a getter.
  bool get isStrictSetter => this is Procedure && (this as Procedure).isSetter;

  bool get isNonFinalField => this is Field && !(this as Field).isFinal;

  bool get isGetter =>
      this is Field || (this is Procedure && (this as Procedure).isGetter);

  bool get isSetter =>
      isNonFinalField || (this is Procedure && (this as Procedure).isSetter);

  bool get isMethod =>
      this is Procedure && (this as Procedure).kind == ProcedureKind.Method;
}
