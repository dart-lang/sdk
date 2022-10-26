// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/fasta_codes.dart'
    show
        templateJsInteropExportInvalidInteropTypeArgument,
        templateJsInteropExportInvalidTypeArgument,
        templateJsInteropStaticInteropMockNotStaticInteropType;
import 'package:kernel/ast.dart';
import 'package:kernel/target/targets.dart';
import 'package:kernel/type_environment.dart';
import 'package:_fe_analyzer_shared/src/messages/codes.dart'
    show
        Message,
        LocatedMessage,
        templateJsInteropExportClassNotMarkedExportable,
        templateJsInteropExportDartInterfaceHasNonEmptyJSExportValue,
        templateJsInteropExportDisallowedMember,
        templateJsInteropExportMemberCollision,
        templateJsInteropExportNoExportableMembers,
        templateJsInteropStaticInteropMockMissingGetterOrSetter,
        templateJsInteropStaticInteropMockMissingImplements;
import 'package:_js_interop_checks/src/js_interop.dart' as js_interop;

enum _ExportStatus {
  EXPORT_ERROR,
  NON_EXPORTABLE,
  EXPORTABLE,
}

class _GetSet {
  Member? getter;
  Member? setter;

  _GetSet(this.getter, this.setter);
}

class ExportChecker {
  final DiagnosticReporter<Message, LocatedMessage> _diagnosticReporter;
  final Map<Reference, Map<String, Set<Member>>> exportClassToMemberMap = {};
  final Map<Reference, _ExportStatus> exportStatus = {};
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
  _GetSet getGetterSetter(Set<Member> exports) {
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

    return _GetSet(getter, setter);
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
        memberMap[memberName + '='] = member;
      } else {
        if (member is Field && !member.isFinal) {
          memberMap[memberName + '='] = member;
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
        exportStatus[cls.reference] != _ExportStatus.EXPORTABLE) {
      exportStatus[cls.reference] = _ExportStatus.NON_EXPORTABLE;
      return;
    }

    if (classHasJSExport && js_interop.getJSExportName(cls).isNotEmpty) {
      _diagnosticReporter.report(
          templateJsInteropExportDartInterfaceHasNonEmptyJSExportValue
              .withArguments(cls.name),
          cls.fileOffset,
          cls.name.length,
          cls.location?.file);
      exportStatus[cls.reference] = _ExportStatus.EXPORT_ERROR;
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
      exportStatus[cls.reference] = _ExportStatus.EXPORT_ERROR;
    }

    if (exports.isEmpty) {
      _diagnosticReporter.report(
          templateJsInteropExportNoExportableMembers.withArguments(cls.name),
          cls.fileOffset,
          cls.name.length,
          cls.location?.file);
      exportStatus[cls.reference] = _ExportStatus.EXPORT_ERROR;
    }

    exportClassToMemberMap[cls.reference] = exports;
    exportStatus[cls.reference] ??= _ExportStatus.EXPORTABLE;
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
          exportStatus[cls.reference] = _ExportStatus.EXPORT_ERROR;
        }
      } else {
        // Mark as exportable so we know that the class has an exportable member
        // when we process the class later.
        if (cls != null) exportStatus[cls.reference] = _ExportStatus.EXPORTABLE;
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

class StaticInteropMockValidator {
  final Map<ExtensionMemberDescriptor, String> _descriptorToExtensionName = {};
  final DiagnosticReporter<Message, LocatedMessage> _diagnosticReporter;
  final ExportChecker _exportChecker;
  // Cache of @staticInterop classes to a mapping between their extension
  // members and those members' export names.
  final Map<Class, Map<String, Set<ExtensionMemberDescriptor>>>
      _staticInteropExportNameToDescriptorMap = {};
  final TypeEnvironment _typeEnvironment;
  late final Map<Reference, Set<Extension>>
      _staticInteropClassesWithExtensions = _computeStaticInteropExtensionMap();
  StaticInteropMockValidator(
      this._diagnosticReporter, this._exportChecker, this._typeEnvironment);

  bool validateStaticInteropTypeArgument(
      StaticInvocation node, DartType staticInteropType) {
    if (staticInteropType is! InterfaceType ||
        !js_interop.hasStaticInteropAnnotation(staticInteropType.classNode)) {
      _diagnosticReporter.report(
          templateJsInteropStaticInteropMockNotStaticInteropType.withArguments(
              staticInteropType, true),
          node.fileOffset,
          node.name.text.length,
          node.location?.file);
      return false;
    }
    return true;
  }

  /// Given an invocation [node] of `js_util.createStaticInteropMock`, and its
  /// type arguments [staticInteropClass] and [dartClass], checks that the
  /// [dartClass] has sufficient members to be exported in place of
  /// [staticInteropClass].
  bool validateCreateStaticInteropMock(
      StaticInvocation node, Class staticInteropClass, Class dartClass) {
    var conformanceError = false;
    var exportNameToDescriptors =
        _computeImplementableExtensionMembers(staticInteropClass);
    var exportMap = _exportChecker.exportClassToMemberMap[dartClass.reference]!;

    for (var exportName in exportNameToDescriptors.keys) {
      var descriptors = exportNameToDescriptors[exportName]!;

      String getAsErrorString(Iterable<ExtensionMemberDescriptor> descriptors) {
        var withExtensionNameAndType = descriptors.map((descriptor) {
          var extension = _descriptorToExtensionName[descriptor]!;
          var name = descriptor.name.text;
          var type = _getTypeOfDescriptor(descriptor);
          if (descriptor.isGetter) {
            type = FunctionType([], type, Nullability.nonNullable);
          } else if (descriptor.isSetter) {
            type = FunctionType([type], VoidType(), Nullability.nonNullable);
            name += '=';
          }
          return '$extension.$name ($type)';
        }).toList()
          ..sort();
        return withExtensionNameAndType.join(', ');
      }

      // Unlike with class members, there's no guarantee that there aren't
      // conflicting members. We take a conservative approach with our error
      // checking, and just require one of the extension members with the export
      // name be implemented in the mocking class. It's typically unusual to
      // have conflicting members for the same interface, so this should be
      // satisfactory in most cases.
      var hasImplementation = false;
      var dartMembers = exportMap[exportName];
      if (dartMembers != null) {
        var firstMember = dartMembers.first;
        if (firstMember.isMethod) {
          hasImplementation = descriptors
              .any((descriptor) => _implements(firstMember, descriptor));
        } else {
          var getSet = _exportChecker.getGetterSetter(dartMembers);

          var getters = <ExtensionMemberDescriptor>{};
          var setters = <ExtensionMemberDescriptor>{};

          var implementsGetter = false;
          var implementsSetter = false;
          for (var descriptor in descriptors) {
            if (descriptor.isGetter) {
              implementsGetter |= _implements(getSet.getter, descriptor);
              getters.add(descriptor);
            } else if (descriptor.isSetter) {
              implementsSetter |= _implements(getSet.setter, descriptor);
              setters.add(descriptor);
            }
          }

          hasImplementation = implementsGetter || implementsSetter;

          // If there is both a getter and setter descriptor, then we require
          // users to provide both a getter and setter that are subtypes.
          // It's likely that declaring one but not the other when both are used
          // in the @staticInterop class is a bug.
          if (getters.isNotEmpty &&
              setters.isNotEmpty &&
              (implementsGetter ^ implementsSetter)) {
            _diagnosticReporter.report(
                templateJsInteropStaticInteropMockMissingGetterOrSetter
                    .withArguments(
                        dartClass.name,
                        implementsGetter ? 'getter' : 'setter',
                        implementsGetter ? 'setter' : 'getter',
                        exportName,
                        getAsErrorString(implementsGetter ? setters : getters)),
                node.fileOffset,
                node.name.text.length,
                node.location?.file);
            // While we do have an implementation, this is still an error.
            conformanceError = true;
          }
        }
      }

      if (!hasImplementation) {
        _diagnosticReporter.report(
            templateJsInteropStaticInteropMockMissingImplements.withArguments(
                dartClass.name, exportName, getAsErrorString(descriptors)),
            node.fileOffset,
            node.name.text.length,
            node.location?.file);
        conformanceError = true;
      }
    }
    return !conformanceError;
  }

  // Get the corresponding function type of the given descriptor. Getters and
  // setters return their return and parameter types, respectively.
  DartType _getTypeOfDescriptor(ExtensionMemberDescriptor interopDescriptor) {
    // CFE creates static procedures for each extension member.
    var interopMember = interopDescriptor.member.asProcedure;

    if (interopDescriptor.isGetter) {
      return interopMember.function.returnType;
    } else if (interopDescriptor.isSetter) {
      // Ignore the first argument `this` in the generated procedure.
      return interopMember.function.positionalParameters[1].type;
    } else {
      assert(interopDescriptor.isMethod);
      var interopMemberType =
          interopMember.function.computeFunctionType(Nullability.nonNullable);
      // Ignore the first argument `this` in the generated procedure.
      return FunctionType(
          interopMemberType.positionalParameters.skip(1).toList(),
          interopMemberType.returnType,
          interopMemberType.declaredNullability,
          namedParameters: interopMemberType.namedParameters,
          typeParameters: interopMemberType.typeParameters,
          requiredParameterCount: interopMemberType.requiredParameterCount - 1);
    }
  }

  // Determine if the given Dart member is the right kind and subtype to
  // implement the descriptor.
  bool _implements(
      Member? dartMember, ExtensionMemberDescriptor interopDescriptor) {
    if (dartMember == null) return false;

    // If it isn't even the right kind, don't continue.
    if (interopDescriptor.isGetter && !dartMember.isGetter) {
      return false;
    } else if (interopDescriptor.isSetter && !dartMember.isSetter) {
      return false;
    } else if (interopDescriptor.isMethod && dartMember is! Procedure) {
      return false;
    }

    bool isSubtypeOf(DartType dartType, DartType interopType) {
      return _typeEnvironment.isSubtypeOf(
          dartType, interopType, SubtypeCheckMode.withNullabilities);
    }

    var interopType = _getTypeOfDescriptor(interopDescriptor);

    if (interopDescriptor.isGetter) {
      if (!isSubtypeOf(dartMember.getterType, interopType)) {
        return false;
      }
    } else if (interopDescriptor.isSetter) {
      if (!isSubtypeOf(interopType, dartMember.setterType)) {
        return false;
      }
    } else if (interopDescriptor.isMethod) {
      if (!isSubtypeOf(
          (dartMember as Procedure)
              .function
              .computeFunctionType(Nullability.nonNullable),
          interopType)) {
        return false;
      }
    }
    return true;
  }

  /// Compute a mapping between all the @staticInterop classes and their
  /// extensions.
  ///
  /// We do this here instead of in the export checker for two reasons:
  /// 1. Modular compilation may invalidate extensions, so we need some way to
  /// get rid of old extensions.
  /// 2. The work to do this is only done when you use the
  /// `createStaticInteropMock` API, leaving unrelated libraries alone.
  ///
  /// TODO(srujzs): This does not take into account any scoping. This might mean
  /// that if another library defines an extension on the @staticInterop class
  /// that is outside of the scope of the current library, this API will report
  /// an error. Considering this API should primarily be used in tests, such a
  /// compilation will be unlikely, but we should revisit this.
  Map<Reference, Set<Extension>> _computeStaticInteropExtensionMap() {
    // Process the stored libaries, and create a mapping between @staticInterop
    // classes and their extensions.
    var staticInteropClassesWithExtensions = <Reference, Set<Extension>>{};
    for (var library in ExportChecker.libraryExtensionMap.keys) {
      for (var extension in ExportChecker.libraryExtensionMap[library]!) {
        var onType = extension.onType as InterfaceType;
        staticInteropClassesWithExtensions
            .putIfAbsent(onType.className, () => {})
            .add(extension);
      }
    }
    return staticInteropClassesWithExtensions;
  }

  /// Returns a map between all the implementable external extension member
  /// names and the descriptors that have that name for [staticInteropClass].
  ///
  /// Also computes a mapping between descriptors and their name for error
  /// reporting.
  Map<String, Set<ExtensionMemberDescriptor>>
      _computeImplementableExtensionMembers(Class staticInteropClass) {
    assert(js_interop.hasStaticInteropAnnotation(staticInteropClass));

    // Get the cached result if we've already processed this class.
    var exportNameToDescriptors =
        _staticInteropExportNameToDescriptorMap[staticInteropClass];
    if (exportNameToDescriptors != null) {
      return exportNameToDescriptors;
    } else {
      exportNameToDescriptors = <String, Set<ExtensionMemberDescriptor>>{};
    }

    var classes = <Class>{};
    // Compute a map of all the possible descriptors available in this type and
    // the supertypes.
    void getAllDescriptors(Class cls) {
      if (classes.add(cls)) {
        var extensions = _staticInteropClassesWithExtensions[cls.reference];
        if (extensions != null) {
          for (var extension in extensions) {
            for (var descriptor in extension.members) {
              if (!descriptor.isExternal || descriptor.isStatic) continue;
              // No need to handle external fields - they are transformed to
              // external getters/setters by the CFE.
              if (!descriptor.isGetter &&
                  !descriptor.isSetter &&
                  !descriptor.isMethod) {
                continue;
              }
              _descriptorToExtensionName[descriptor] =
                  extension.isUnnamedExtension ? '<unnamed>' : extension.name;
              var name = js_interop.getJSName(descriptor.member.asMember);
              if (name.isEmpty) name = descriptor.name.text;
              exportNameToDescriptors!
                  .putIfAbsent(name, () => {})
                  .add(descriptor);
            }
          }
        }
        cls.supers.forEach((Supertype supertype) {
          getAllDescriptors(supertype.classNode);
        });
      }
    }

    getAllDescriptors(staticInteropClass);

    return _staticInteropExportNameToDescriptorMap[staticInteropClass] =
        exportNameToDescriptors;
  }
}

// TODO(srujzs): Rename this class and file to focus on exports. Separate out
// the export creation, export validation, and mock validation into three
// separate files to make this cleaner.
class StaticInteropMockCreator extends Transformer {
  final Procedure _allowInterop;
  final Procedure _createDartExport;
  final Procedure _createStaticInteropMock;
  final DiagnosticReporter<Message, LocatedMessage> _diagnosticReporter;
  final ExportChecker _exportChecker;
  final InterfaceType _functionType;
  final Procedure _getProperty;
  final Procedure _globalThis;
  final InterfaceType _objectType;
  final Procedure _setProperty;
  final StaticInteropMockValidator _staticInteropMockValidator;
  final TypeEnvironment _typeEnvironment;

  StaticInteropMockCreator(
      this._typeEnvironment, this._diagnosticReporter, this._exportChecker)
      : _allowInterop = _typeEnvironment.coreTypes.index
            .getTopLevelProcedure('dart:js', 'allowInterop'),
        _createDartExport = _typeEnvironment.coreTypes.index
            .getTopLevelProcedure('dart:js_util', 'createDartExport'),
        _createStaticInteropMock = _typeEnvironment.coreTypes.index
            .getTopLevelProcedure('dart:js_util', 'createStaticInteropMock'),
        _functionType = _typeEnvironment.coreTypes.functionNonNullableRawType,
        _getProperty = (_typeEnvironment.coreTypes.index.tryGetTopLevelMember(
                'dart:js_util', '_getPropertyTrustType') ??
            _typeEnvironment.coreTypes.index.getTopLevelProcedure(
                'dart:js_util', 'getProperty')) as Procedure,
        _globalThis = _typeEnvironment.coreTypes.index
            .getTopLevelProcedure('dart:js_util', 'get:globalThis'),
        _objectType = _typeEnvironment.coreTypes.objectNonNullableRawType,
        _setProperty = (_typeEnvironment.coreTypes.index.tryGetTopLevelMember(
                'dart:js_util', '_setPropertyUnchecked') ??
            _typeEnvironment.coreTypes.index.getTopLevelProcedure(
                'dart:js_util', 'setProperty')) as Procedure,
        _staticInteropMockValidator = StaticInteropMockValidator(
            _diagnosticReporter, _exportChecker, _typeEnvironment);

  @override
  TreeNode visitStaticInvocation(StaticInvocation node) {
    if (node.target == _createDartExport) {
      var typeArguments = node.arguments.types;
      assert(typeArguments.length == 1);
      if (_verifyExportable(node, typeArguments[0])) {
        return _createExport(node, typeArguments[0] as InterfaceType);
      }
    } else if (node.target == _createStaticInteropMock) {
      var typeArguments = node.arguments.types;
      assert(typeArguments.length == 2);
      var staticInteropType = typeArguments[0];
      var dartType = typeArguments[1];

      var exportable = _verifyExportable(node, dartType);
      var staticInteropTypeArgumentCorrect = _staticInteropMockValidator
          .validateStaticInteropTypeArgument(node, staticInteropType);
      if (exportable &&
          staticInteropTypeArgumentCorrect &&
          _staticInteropMockValidator.validateCreateStaticInteropMock(
              node,
              (staticInteropType as InterfaceType).classNode,
              (dartType as InterfaceType).classNode)) {
        var arguments = node.arguments.positional;
        assert(arguments.length == 1 || arguments.length == 2);
        var proto = arguments.length == 2 ? arguments[1] : null;

        return _createExport(node, dartType, staticInteropType, proto);
      }
    }
    return node;
  }

  /// Validate that the [dartType] provided via `createDartExport` can be
  /// exported safely.
  ///
  /// Checks that:
  /// - Type argument is a valid Dart interface type.
  /// - Type argument is not a JS interop type.
  /// - Type argument was not marked as non-exportable.
  ///
  /// If there were no errors with processing the class, returns true.
  /// Otherwise, returns false.
  bool _verifyExportable(StaticInvocation node, DartType dartType) {
    if (dartType is! InterfaceType) {
      _diagnosticReporter.report(
          templateJsInteropExportInvalidTypeArgument.withArguments(
              dartType, true),
          node.fileOffset,
          node.name.text.length,
          node.location?.file);
      return false;
    }
    var dartClass = dartType.classNode;
    if (js_interop.hasJSInteropAnnotation(dartClass) ||
        js_interop.hasStaticInteropAnnotation(dartClass) ||
        js_interop.hasAnonymousAnnotation(dartClass)) {
      _diagnosticReporter.report(
          templateJsInteropExportInvalidInteropTypeArgument.withArguments(
              dartType, true),
          node.fileOffset,
          node.name.text.length,
          node.location?.file);
      return false;
    }
    if (!_exportChecker.exportStatus.containsKey(dartClass.reference)) {
      // This occurs when we deserialize previously compiled modules. Those
      // modules may contain export classes, so we need to revisit the classes
      // in those previously compiled modules if they are used.
      dartClass.procedures
          .forEach((member) => _exportChecker.visitMember(member));
      dartClass.fields.forEach((member) => _exportChecker.visitMember(member));
      _exportChecker.visitClass(dartClass);
    }
    var exportStatus = _exportChecker.exportStatus[dartClass.reference];
    if (exportStatus == _ExportStatus.NON_EXPORTABLE) {
      _diagnosticReporter.report(
          templateJsInteropExportClassNotMarkedExportable
              .withArguments(dartClass.name),
          node.fileOffset,
          node.name.text.length,
          node.location?.file);
      return false;
    }
    return exportStatus == _ExportStatus.EXPORTABLE;
  }

  /// Create the object literal using the export map that was computed from the
  /// interface in [dartType].
  ///
  /// [node] is either a call to `createStaticInteropMock` or
  /// `createDartExport`. [dartType] is assumed to be a valid exportable class.
  /// [returnType] is the type that the object literal will be casted to.
  /// [proto] is an optional prototype object that users can pass to instantiate
  /// the object literal.
  ///
  /// The export map is already validated, so this method simply iterates over
  /// it and either assigns a method for a given property name, or assigns a
  /// getter and/or setter.
  ///
  /// Returns a call to the block of code that instantiates this object literal
  /// and returns it.
  TreeNode _createExport(StaticInvocation node, InterfaceType dartType,
      [DartType? returnType, Expression? proto]) {
    var exportMap =
        _exportChecker.exportClassToMemberMap[dartType.classNode.reference]!;

    var block = <Statement>[];
    returnType ??= _typeEnvironment.coreTypes.objectNonNullableRawType;

    var dartInstance = VariableDeclaration('#dartInstance',
        initializer: node.arguments.positional[0], type: dartType)
      ..fileOffset = node.fileOffset
      ..parent = node.parent;
    block.add(dartInstance);

    // Get the global 'Object' property.
    StaticInvocation getObjectProperty() => StaticInvocation(
        _getProperty,
        Arguments([StaticGet(_globalThis), StringLiteral('Object')],
            types: [_objectType]));

    // Get a fresh object literal, using the proto to create it if one was
    // given.
    StaticInvocation getLiteral([Expression? proto]) {
      return _callMethod(getObjectProperty(), StringLiteral('create'),
          [proto ?? NullLiteral()], _objectType);
    }

    var jsExporter = VariableDeclaration('#jsExporter',
        initializer: AsExpression(getLiteral(proto), returnType),
        type: returnType)
      ..fileOffset = node.fileOffset
      ..parent = node.parent;
    block.add(jsExporter);

    for (var exportName in exportMap.keys) {
      var exports = exportMap[exportName]!;
      ExpressionStatement setProperty(VariableGet jsObject, String propertyName,
          StaticInvocation wrappedValue) {
        // `setProperty(jsObject, propertyName, wrappedValue)`
        return ExpressionStatement(StaticInvocation(
            _setProperty,
            Arguments([jsObject, StringLiteral(propertyName), wrappedValue],
                types: [_objectType])))
          ..fileOffset = node.fileOffset
          ..parent = node.parent;
      }

      var firstExport = exports.first;
      // With methods, there's only one export per export name.
      if (firstExport is Procedure &&
          firstExport.kind == ProcedureKind.Method) {
        // `setProperty(jsMock, jsName, allowInterop(dartMock.tearoffMethod))`
        block.add(setProperty(
            VariableGet(jsExporter),
            exportName,
            StaticInvocation(
                _allowInterop,
                Arguments([
                  InstanceTearOff(InstanceAccessKind.Instance,
                      VariableGet(dartInstance), firstExport.name,
                      interfaceTarget: firstExport,
                      resultType: firstExport.getterType)
                ], types: [
                  _functionType
                ]))));
      } else {
        // Create the mapping from `get` and `set` to their `dartInstance` calls
        // to be used in `Object.defineProperty`.

        // Add the given exports to the mapping that corresponds to the given
        // exportName that is used by `Object.defineProperty`. In order to
        // conform to that API, this function defines 'get' or 'set' properties
        // on a given object literal.
        // The AST code looks like:
        //
        // ```
        // setProperty(getSetMap, 'get', allowInterop(() {
        //   return dartInstance.getter;
        // }));
        // ```
        //
        // in the case of a getter and:
        //
        // ```
        // setProperty(getSetMap, 'set', allowInterop((val) {
        //  dartInstance.setter = val;
        // }));
        // ```
        //
        // in the case of a setter.
        //
        // A new map VariableDeclaration is created and added to the block of
        // statements for each export name.
        var getSetMap = VariableDeclaration('#${exportName}Mapping',
            initializer: getLiteral(), type: _objectType)
          ..fileOffset = node.fileOffset
          ..parent = node.parent;
        block.add(getSetMap);
        var getSet = _exportChecker.getGetterSetter(exports);
        var getter = getSet.getter;
        var setter = getSet.setter;
        if (getter != null) {
          block.add(setProperty(
              VariableGet(getSetMap),
              'get',
              StaticInvocation(
                  _allowInterop,
                  Arguments([
                    FunctionExpression(FunctionNode(ReturnStatement(InstanceGet(
                        InstanceAccessKind.Instance,
                        VariableGet(dartInstance),
                        getter.name,
                        interfaceTarget: getter,
                        resultType: getter.getterType))))
                  ], types: [
                    _functionType
                  ]))));
        }
        if (setter != null) {
          var setterParameter =
              VariableDeclaration('#val', type: setter.setterType)
                ..fileOffset = node.fileOffset
                ..parent = node.parent;
          block.add(setProperty(
              VariableGet(getSetMap),
              'set',
              StaticInvocation(
                  _allowInterop,
                  Arguments([
                    FunctionExpression(FunctionNode(
                        ExpressionStatement(InstanceSet(
                            InstanceAccessKind.Instance,
                            VariableGet(dartInstance),
                            setter.name,
                            VariableGet(setterParameter),
                            interfaceTarget: setter)),
                        positionalParameters: [setterParameter]))
                  ], types: [
                    _functionType
                  ]))));
        }
        // Call `Object.defineProperty` to define the export name with the
        // 'get' and/or 'set' mapping. This allows us to treat get/set
        // semantics as methods.
        block.add(ExpressionStatement(_callMethod(
            getObjectProperty(),
            StringLiteral('defineProperty'),
            [
              VariableGet(jsExporter),
              StringLiteral(exportName),
              VariableGet(getSetMap)
            ],
            VoidType()))
          ..fileOffset = node.fileOffset
          ..parent = node.parent);
      }
    }

    block.add(ReturnStatement(VariableGet(jsExporter)));
    // Return a call to evaluate the entire block of code and return the JS mock
    // that was created.
    return FunctionInvocation(
        FunctionAccessKind.Function,
        FunctionExpression(FunctionNode(Block(block), returnType: returnType)),
        Arguments([]),
        functionType: FunctionType([], returnType, Nullability.nonNullable))
      ..fileOffset = node.fileOffset
      ..parent = node.parent;
  }

  // Optimize `callMethod` calls if possible.
  StaticInvocation _callMethod(Expression object, StringLiteral methodName,
      List<Expression> args, DartType returnType) {
    var index = args.length;
    var callMethodOptimized = _typeEnvironment.coreTypes.index
        .tryGetTopLevelMember(
            'dart:js_util', '_callMethodUncheckedTrustType$index');
    if (callMethodOptimized == null) {
      var callMethod = _typeEnvironment.coreTypes.index
          .getTopLevelProcedure('dart:js_util', 'callMethod');
      return StaticInvocation(
          callMethod,
          Arguments([object, methodName, ListLiteral(args)],
              types: [returnType]));
    } else {
      return StaticInvocation(callMethodOptimized as Procedure,
          Arguments([object, methodName, ...args], types: [returnType]));
    }
  }
}

extension ExtensionMemberDescriptorExtension on ExtensionMemberDescriptor {
  bool get isGetter => this.kind == ExtensionMemberKind.Getter;
  bool get isSetter => this.kind == ExtensionMemberKind.Setter;
  bool get isMethod => this.kind == ExtensionMemberKind.Method;

  bool get isExternal => (this.member.asProcedure).isExternal;
}

extension ProcedureExtension on Procedure {
  // We only care about concrete instance procedures.
  bool get exportable =>
      !this.isAbstract &&
      !this.isStatic &&
      !this.isExtensionMember &&
      !this.isFactory &&
      !this.isExternal &&
      this.kind != ProcedureKind.Operator;
}

extension FieldExtension on Field {
  // We only care about concrete instance fields.
  bool get exportable => !this.isAbstract && !this.isStatic && !this.isExternal;
}

extension MemberExtension on Member {
  // Get the property name that this member will be exported as.
  String get exportPropertyName {
    var rename = js_interop.getJSExportName(this);
    return rename.isEmpty ? this.name.text : rename;
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
      this.isNonFinalField ||
      (this is Procedure && (this as Procedure).isSetter);

  bool get isMethod =>
      this is Procedure && (this as Procedure).kind == ProcedureKind.Method;
}
