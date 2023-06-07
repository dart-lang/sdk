// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: implementation_imports

import 'package:_fe_analyzer_shared/src/messages/codes.dart'
    show
        templateJsInteropStaticInteropMockMissingGetterOrSetter,
        templateJsInteropStaticInteropMockMissingImplements;
import 'package:_js_interop_checks/js_interop_checks.dart'
    show JsInteropDiagnosticReporter;
import 'package:_js_interop_checks/src/js_interop.dart' as js_interop;
import 'package:front_end/src/fasta/fasta_codes.dart'
    show templateJsInteropStaticInteropMockNotStaticInteropType;
import 'package:kernel/ast.dart';
import 'package:kernel/type_environment.dart';

import 'export_checker.dart';

class StaticInteropMockValidator {
  final Map<ExtensionMemberDescriptor, String> _descriptorToExtensionName = {};
  final JsInteropDiagnosticReporter _diagnosticReporter;
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
    // Process the stored libraries, and create a mapping between @staticInterop
    // classes and their extensions.
    var staticInteropClassesWithExtensions = <Reference, Set<Extension>>{};
    for (var library in ExportChecker.libraryExtensionMap.keys) {
      for (var extension in ExportChecker.libraryExtensionMap[library]!) {
        var onType = extension.onType as InterfaceType;
        staticInteropClassesWithExtensions
            .putIfAbsent(onType.classReference, () => {})
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
        for (var supertype in cls.supers) {
          getAllDescriptors(supertype.classNode);
        }
      }
    }

    getAllDescriptors(staticInteropClass);

    return _staticInteropExportNameToDescriptorMap[staticInteropClass] =
        exportNameToDescriptors;
  }
}
