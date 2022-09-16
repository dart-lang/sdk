// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/fasta_codes.dart'
    show
        templateJsInteropStaticInteropMockMemberNotSubtype,
        templateJsInteropStaticInteropMockNotDartInterfaceType,
        templateJsInteropStaticInteropMockNotStaticInteropType;
import 'package:kernel/ast.dart';
import 'package:kernel/target/targets.dart';
import 'package:kernel/type_environment.dart';
import 'package:_fe_analyzer_shared/src/messages/codes.dart'
    show
        Message,
        LocatedMessage,
        templateJsInteropStaticInteropMockMissingOverride,
        templateJsInteropStaticInteropMockExternalExtensionMemberConflict;
import 'package:_js_interop_checks/src/js_interop.dart' as js_interop;

class _ExtensionVisitor extends RecursiveVisitor {
  final Map<Reference, Extension> staticInteropClassesWithExtensions;

  _ExtensionVisitor(this.staticInteropClassesWithExtensions);

  @override
  void visitExtension(Extension extension) {
    // TODO(srujzs): This code was written with the assumption there would be
    // one single extension per `@staticInterop` class. This is no longer true
    // and this code needs to be refactored to handle multiple extensions.
    var onType = extension.onType;
    if (onType is InterfaceType &&
        js_interop.hasStaticInteropAnnotation(onType.classNode)) {
      if (!staticInteropClassesWithExtensions.containsKey(onType.className)) {
        staticInteropClassesWithExtensions[onType.className] = extension;
      }
    }
    super.visitExtension(extension);
  }
}

class StaticInteropMockCreator extends Transformer {
  final Procedure _allowInterop;
  final Procedure _callMethod;
  final Procedure _createStaticInteropMock;
  final DiagnosticReporter<Message, LocatedMessage> _diagnosticReporter;
  late final _ExtensionVisitor _extensionVisitor;
  final InterfaceType _functionType;
  final Procedure _getProperty;
  final Procedure _globalThis;
  final InterfaceType _objectType;
  final Procedure _setProperty;
  final Map<Reference, Extension> _staticInteropClassesWithExtensions = {};
  final TypeEnvironment _typeEnvironment;

  StaticInteropMockCreator(this._typeEnvironment, this._diagnosticReporter)
      : _allowInterop = _typeEnvironment.coreTypes.index
            .getTopLevelProcedure('dart:js', 'allowInterop'),
        _callMethod = _typeEnvironment.coreTypes.index
            .getTopLevelProcedure('dart:js_util', 'callMethod'),
        _createStaticInteropMock = _typeEnvironment.coreTypes.index
            .getTopLevelProcedure('dart:js_util', 'createStaticInteropMock'),
        _functionType = _typeEnvironment.coreTypes.functionNonNullableRawType,
        _getProperty = _typeEnvironment.coreTypes.index
            .getTopLevelProcedure('dart:js_util', 'getProperty'),
        _globalThis = _typeEnvironment.coreTypes.index
            .getTopLevelProcedure('dart:js_util', 'get:globalThis'),
        _objectType = _typeEnvironment.coreTypes.objectNonNullableRawType,
        _setProperty = _typeEnvironment.coreTypes.index
            .getTopLevelProcedure('dart:js_util', 'setProperty') {
    _extensionVisitor = _ExtensionVisitor(_staticInteropClassesWithExtensions);
  }

  void processExtensions(Library library) =>
      _extensionVisitor.visitLibrary(library);

  @override
  TreeNode visitStaticInvocation(StaticInvocation node) {
    if (node.target != _createStaticInteropMock) return node;
    var typeArguments = node.arguments.types;
    assert(typeArguments.length == 2);
    var staticInteropType = typeArguments[0];
    var dartType = typeArguments[1];
    var typeArgumentsError = false;
    if (staticInteropType is! InterfaceType ||
        staticInteropType.declaredNullability != Nullability.nonNullable ||
        !js_interop.hasStaticInteropAnnotation(staticInteropType.classNode)) {
      _diagnosticReporter.report(
          templateJsInteropStaticInteropMockNotStaticInteropType.withArguments(
              staticInteropType, true),
          node.fileOffset,
          node.name.text.length,
          node.location?.file);
      typeArgumentsError = true;
    }
    if (dartType is! InterfaceType ||
        dartType.declaredNullability != Nullability.nonNullable ||
        js_interop.hasJSInteropAnnotation(dartType.classNode) ||
        js_interop.hasStaticInteropAnnotation(dartType.classNode) ||
        js_interop.hasAnonymousAnnotation(dartType.classNode)) {
      _diagnosticReporter.report(
          templateJsInteropStaticInteropMockNotDartInterfaceType.withArguments(
              dartType, true),
          node.fileOffset,
          node.name.text.length,
          node.location?.file);
      typeArgumentsError = true;
    }
    // Can't proceed with these errors.
    if (typeArgumentsError) return node;

    var staticInteropClass = (staticInteropType as InterfaceType).classNode;
    var dartClass = (dartType as InterfaceType).classNode;

    var dartMemberMap = <String, Member>{};
    for (var procedure in dartClass.allInstanceProcedures) {
      // We only care about concrete instance getters, setters, and methods.
      if (procedure.isAbstract ||
          procedure.isStatic ||
          procedure.isExtensionMember ||
          procedure.isFactory) {
        continue;
      }
      var name = procedure.name.text;
      // Add a suffix to differentiate getters and setters.
      if (procedure.isSetter) name += '=';
      dartMemberMap[name] = procedure;
    }
    for (var field in dartClass.allInstanceFields) {
      // We only care about concrete instance fields.
      if (field.isAbstract || field.isStatic) continue;
      var name = field.name.text;
      dartMemberMap[name] = field;
      if (!field.isFinal) {
        // Add the setter.
        name += '=';
        dartMemberMap[name] = field;
      }
    }

    var conformanceError = false;
    var nameToDescriptors = <String, List<ExtensionMemberDescriptor>>{};
    var descriptorToClass = <ExtensionMemberDescriptor, Class>{};
    staticInteropClass.computeAllNonStaticExternalExtensionMembers(
        nameToDescriptors,
        descriptorToClass,
        _staticInteropClassesWithExtensions,
        _typeEnvironment);
    for (var descriptorName in nameToDescriptors.keys) {
      var descriptors = nameToDescriptors[descriptorName]!;
      // In the case of a getter/setter, we may have 2 descriptors per extension
      // with the same name, and therefore per class. So, only get one
      // descriptor per class to determine if there are conflicts.
      var visitedClasses = <Class>{};
      var descriptorConflicts = <ExtensionMemberDescriptor>{};
      for (var descriptor in descriptors) {
        if (visitedClasses.add(descriptorToClass[descriptor]!)) {
          descriptorConflicts.add(descriptor);
        }
      }
      if (descriptorConflicts.length > 1) {
        // Conflict, report an error.
        var violations = <String>[];
        for (var descriptor in descriptorConflicts) {
          var cls = descriptorToClass[descriptor]!;
          var extension = _staticInteropClassesWithExtensions[cls.reference]!;
          var extensionName =
              extension.isUnnamedExtension ? 'unnamed' : extension.name;
          violations.add("'${cls.name}.$extensionName'");
        }
        // Sort violations so error expectations can be deterministic.
        violations.sort();
        _diagnosticReporter.report(
            templateJsInteropStaticInteropMockExternalExtensionMemberConflict
                .withArguments(descriptorName, violations.join(', ')),
            node.fileOffset,
            node.name.text.length,
            node.location?.file);
        conformanceError = true;
        continue;
      }
      // With no conflicts, there should be either just 1 entry or 2 entries
      // where one is a getter and the other is a setter in the same extension
      // (and therefore the same @staticInterop class).
      assert(descriptors.length == 1 || descriptors.length == 2);
      if (descriptors.length == 2) {
        var first = descriptors[0];
        var second = descriptors[1];
        assert(descriptorToClass[first]! == descriptorToClass[second]!);
        assert((first.isGetter && second.isSetter) ||
            (first.isSetter && second.isGetter));
      }
      for (var interopDescriptor in descriptors) {
        var dartMemberName = descriptorName;
        // Distinguish getters and setters for overriding conformance.
        if (interopDescriptor.isSetter) dartMemberName += '=';

        // Determine whether the Dart instance member with the same name as the
        // `@staticInterop` procedure is the right type of member such that it
        // can be considered an override.
        bool validOverridingMemberType() {
          var dartMember = dartMemberMap[dartMemberName]!;
          if (interopDescriptor.isGetter &&
              dartMember is! Field &&
              !(dartMember as Procedure).isGetter) {
            return false;
          } else if (interopDescriptor.isSetter &&
              dartMember is! Field &&
              !(dartMember as Procedure).isSetter) {
            return false;
          } else if (interopDescriptor.isMethod && dartMember is! Procedure) {
            return false;
          }
          return true;
        }

        if (!dartMemberMap.containsKey(dartMemberName) ||
            !validOverridingMemberType()) {
          _diagnosticReporter.report(
              templateJsInteropStaticInteropMockMissingOverride.withArguments(
                  staticInteropClass.name, dartMemberName, dartClass.name),
              node.fileOffset,
              node.name.text.length,
              node.location?.file);
          conformanceError = true;
          continue;
        }
        var dartMember = dartMemberMap[dartMemberName]!;

        // Determine if the given type of the Dart member is a valid subtype of
        // the given type of the `@staticInterop` member. If not, report an
        // error to the user.
        bool overrideIsSubtype(DartType? dartType, DartType? interopType) {
          if (dartType == null ||
              interopType == null ||
              !_typeEnvironment.isSubtypeOf(
                  dartType, interopType, SubtypeCheckMode.withNullabilities)) {
            _diagnosticReporter.report(
                templateJsInteropStaticInteropMockMemberNotSubtype
                    .withArguments(
                        dartClass.name,
                        dartMemberName,
                        dartType ?? NullType(),
                        staticInteropClass.name,
                        dartMemberName,
                        interopType ?? NullType(),
                        true),
                node.fileOffset,
                node.name.text.length,
                node.location?.file);
            return false;
          }
          return true;
        }

        // CFE creates static procedures for each extension member.
        var interopMember = interopDescriptor.member.asProcedure;
        DartType getGetterFunctionType(DartType getterType) {
          return FunctionType([], getterType, Nullability.nonNullable);
        }

        DartType getSetterFunctionType(DartType setterType) {
          return FunctionType(
              [setterType], VoidType(), Nullability.nonNullable);
        }

        if (interopDescriptor.isGetter &&
            !overrideIsSubtype(getGetterFunctionType(dartMember.getterType),
                getGetterFunctionType(interopMember.function.returnType))) {
          conformanceError = true;
          continue;
        } else if (interopDescriptor.isSetter &&
            !overrideIsSubtype(
                getSetterFunctionType(dartMember.setterType),
                // Ignore the first argument `this` in the generated procedure.
                getSetterFunctionType(
                    interopMember.function.positionalParameters[1].type))) {
          conformanceError = true;
          continue;
        } else if (interopDescriptor.isMethod) {
          var interopMemberType = interopMember.function
              .computeFunctionType(Nullability.nonNullable);
          // Ignore the first argument `this` in the generated procedure.
          interopMemberType = FunctionType(
              interopMemberType.positionalParameters.skip(1).toList(),
              interopMemberType.returnType,
              interopMemberType.declaredNullability,
              namedParameters: interopMemberType.namedParameters,
              typeParameters: interopMemberType.typeParameters,
              requiredParameterCount:
                  interopMemberType.requiredParameterCount - 1);
          if (!overrideIsSubtype(
              (dartMember as Procedure)
                  .function
                  .computeFunctionType(Nullability.nonNullable),
              interopMemberType)) {
            conformanceError = true;
            continue;
          }
        }
      }
    }
    // The interfaces do not conform and therefore we can't create a mock.
    if (conformanceError) return node;
    // Everything conforms, we can safely create a mock and replace this
    // invocation with it.
    return _createMock(
        node, nameToDescriptors, descriptorToClass, dartMemberMap);
  }

  TreeNode _createMock(
      StaticInvocation node,
      Map<String, List<ExtensionMemberDescriptor>> nameToDescriptors,
      Map<ExtensionMemberDescriptor, Class> descriptorToClass,
      Map<String, Member> dartMemberMap) {
    var block = <Statement>[];
    assert(node.arguments.positional.length == 1);
    var interopType = node.arguments.types[0];
    var dartType = node.arguments.types[1];

    var dartMock = VariableDeclaration('#dartMock',
        initializer: node.arguments.positional[0], type: dartType)
      ..fileOffset = node.fileOffset
      ..parent = node.parent;
    block.add(dartMock);

    // Get the global 'Object' property.
    StaticInvocation getObjectProperty() => StaticInvocation(
        _getProperty,
        Arguments([StaticGet(_globalThis), StringLiteral('Object')],
            types: [_objectType]));

    // Get a fresh object literal.
    // TODO(srujzs): Add prototype option for instance checks.
    StaticInvocation getLiteral() {
      return StaticInvocation(
          _callMethod,
          Arguments([
            getObjectProperty(),
            StringLiteral('create'),
            ListLiteral([NullLiteral()]),
          ], types: [
            _objectType
          ]));
    }

    var jsMock = VariableDeclaration('#jsMock',
        initializer: AsExpression(getLiteral(), interopType), type: interopType)
      ..fileOffset = node.fileOffset
      ..parent = node.parent;
    block.add(jsMock);

    // Keep a map of all the mappings we use for `Object.defineProperty`. It's
    // possible that different descriptors might have the same rename, and it's
    // invalid to redefine a property. This is used in `createAndOrAddToMapping`
    // below.
    var jsNameToGetSetMap = <String, VariableDeclaration>{};
    for (var descriptorName in nameToDescriptors.keys) {
      var descriptors = nameToDescriptors[descriptorName]!;
      var descriptor = descriptors[0];
      // Do any necessary renaming from the `@JS()` annotation.
      String getJSName(ExtensionMemberDescriptor desc) {
        var name = js_interop.getJSName(desc.member.asProcedure);
        return name.isEmpty ? descriptorName : name;
      }

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

      var jsName = getJSName(descriptor);
      if (descriptor.isMethod) {
        var target = dartMemberMap[descriptorName]! as Procedure;
        // `setProperty(jsMock, jsName, allowInterop(dartMock.tearoffMethod))`
        block.add(setProperty(
            VariableGet(jsMock),
            jsName,
            StaticInvocation(
                _allowInterop,
                Arguments([
                  InstanceTearOff(InstanceAccessKind.Instance,
                      VariableGet(dartMock), target.name,
                      interfaceTarget: target, resultType: target.getterType)
                ], types: [
                  _functionType
                ]))));
      } else {
        // Create the mapping from `get` and `set` to their `dartMock` calls to
        // be used in `Object.defineProperty`.

        // Add the given descriptor to the mapping that corresponds to the given
        // JS name that is used by `Object.defineProperty`. In order to conform
        // to that API, this function defines 'get' or 'set' properties on a
        // given object literal.
        // The AST code looks like:
        //
        // ```
        // setProperty(getSetMap, 'get', allowInterop(() {
        //   return dartMock.getter;
        // }));
        // ```
        //
        // in the case of a getter and:
        //
        // ```
        // setProperty(getSetMap, 'set', allowInterop((val) {
        //  dartMock.setter = val;
        // }));
        // ```
        //
        // in the case of a setter.
        //
        // In the case where a mapping does not exist yet for the JS name, a new
        // VariableDeclaration is created and added to the block of statements.
        ExpressionStatement createAndOrAddToMapping(
            ExtensionMemberDescriptor desc,
            String jsName,
            List<Statement> block) {
          if (!jsNameToGetSetMap.containsKey(jsName)) {
            jsNameToGetSetMap[jsName] = VariableDeclaration('#${jsName}Mapping',
                initializer: getLiteral(), type: _objectType)
              ..fileOffset = node.fileOffset
              ..parent = node.parent;
            block.add(jsNameToGetSetMap[jsName]!);
          }
          var getSetMap = jsNameToGetSetMap[jsName]!;
          var dartTarget = desc.isGetter
              ? dartMemberMap[descriptorName]!
              : dartMemberMap[descriptorName + '=']!;
          // Parameter needed in case the descriptor is a setter.
          var setterParameter =
              VariableDeclaration('#val', type: dartTarget.setterType)
                ..fileOffset = node.fileOffset
                ..parent = node.parent;
          return setProperty(
              VariableGet(getSetMap),
              desc.isGetter ? 'get' : 'set',
              desc.isGetter
                  ? StaticInvocation(
                      _allowInterop,
                      Arguments([
                        FunctionExpression(FunctionNode(ReturnStatement(
                            InstanceGet(InstanceAccessKind.Instance,
                                VariableGet(dartMock), dartTarget.name,
                                interfaceTarget: dartTarget,
                                resultType: dartTarget.getterType))))
                      ], types: [
                        _functionType
                      ]))
                  : StaticInvocation(
                      _allowInterop,
                      Arguments([
                        FunctionExpression(FunctionNode(
                            ExpressionStatement(InstanceSet(
                                InstanceAccessKind.Instance,
                                VariableGet(dartMock),
                                dartTarget.name,
                                VariableGet(setterParameter),
                                interfaceTarget: dartTarget)),
                            positionalParameters: [setterParameter]))
                      ], types: [
                        _functionType
                      ])));
        }

        var jsName = getJSName(descriptor);
        block.add(createAndOrAddToMapping(descriptor, jsName, block));
        if (descriptors.length == 2) {
          var secondDescriptor = descriptors[1];
          var secondJsName = getJSName(secondDescriptor);
          block.add(
              createAndOrAddToMapping(secondDescriptor, secondJsName, block));
          if (secondJsName != jsName) {
            // Getter and setter's JS names don't match, we will use the new
            // mapping. This is likely a bug, so print a warning but proceed
            // anyways.
            var classRef =
                descriptorToClass[nameToDescriptors[descriptorName]![0]]!;
            print('WARNING: ${classRef.name} has getter and setter named '
                '$descriptorName, but do not share the same JS name: $jsName '
                'and $secondJsName. Proceeding anyways...');
          }
        }
      }
    }
    // Call `Object.defineProperty` to define the descriptor name with the 'get'
    // and/or 'set' mapping. This allows us to treat get/set semantics as
    // methods.
    for (var jsName in jsNameToGetSetMap.keys) {
      block.add(ExpressionStatement(StaticInvocation(
          _callMethod,
          Arguments([
            getObjectProperty(),
            StringLiteral('defineProperty'),
            ListLiteral([
              VariableGet(jsMock),
              StringLiteral(jsName),
              VariableGet(jsNameToGetSetMap[jsName]!)
            ])
          ], types: [
            VoidType()
          ])))
        ..fileOffset = node.fileOffset
        ..parent = node.parent);
    }

    block.add(ReturnStatement(VariableGet(jsMock)));
    // Return a call to evaluate the entire block of code and return the JS mock
    // that was created.
    return FunctionInvocation(
        FunctionAccessKind.Function,
        FunctionExpression(FunctionNode(Block(block), returnType: interopType)),
        Arguments([]),
        functionType: FunctionType([], interopType, Nullability.nonNullable))
      ..fileOffset = node.fileOffset
      ..parent = node.parent;
  }
}

extension _DartClassExtension on Class {
  List<Procedure> get allInstanceProcedures {
    var allProcs = <Procedure>[];
    Class? cls = this;
    // We only care about instance procedures that have a body.
    bool isInstanceProcedure(Procedure proc) =>
        !proc.isAbstract &&
        !proc.isStatic &&
        !proc.isExtensionMember &&
        !proc.isFactory;
    while (cls != null) {
      allProcs.addAll(cls.procedures.where(isInstanceProcedure));
      // Mixin members override the given superclass' members, but are
      // overridden by the class' instance members, so they are inserted next.
      if (cls.isMixinApplication) {
        allProcs.addAll(cls.mixin.procedures.where(isInstanceProcedure));
      }
      cls = cls.superclass;
    }
    // We inserted procedures from subtype to supertypes, so reverse them so
    // that overridden members come first, with their overrides last.
    return allProcs.reversed.toList();
  }

  List<Field> get allInstanceFields {
    var allFields = <Field>[];
    Class? cls = this;
    bool isInstanceField(Field field) => !field.isAbstract && !field.isStatic;
    while (cls != null) {
      allFields.addAll(cls.fields.where(isInstanceField));
      if (cls.isMixinApplication) {
        allFields.addAll(cls.mixin.fields.where(isInstanceField));
      }
      cls = cls.superclass;
    }
    return allFields.reversed.toList();
  }
}

extension _StaticInteropClassExtension on Class {
  /// Sets [nameToDescriptors] to be a map between all the available external
  /// extension member names and the descriptors that have that name, and also
  /// sets [descriptorToClass] to be a mapping between every external extension
  /// member and its on-type.
  ///
  /// [staticInteropClassesWithExtensions] is a map between all the
  /// `@staticInterop` classes and their singular extension. [typeEnvironment]
  /// is the current component's `TypeEnvironment`.
  ///
  /// Note: The algorithm to determine the most-specific extension member in the
  /// event of name collisions does not conform to the specificity rules
  /// described here:
  /// https://github.com/dart-lang/language/blob/master/accepted/2.7/static-extension-methods/feature-specification.md#specificity.
  /// Instead, it only uses subtype checking of the on-types to find the most
  /// specific member. This is mostly benign as:
  /// 1. There's a single extension per @staticInterop class, so conflicts occur
  /// between classes and not within them.
  /// 2. Generics in the context of interop are by design supposed to be more
  /// rare, and external extension members are already disallowed from using
  /// type parameters. This lowers the importance of checking for instantiation
  /// to bounds.
  void computeAllNonStaticExternalExtensionMembers(
      Map<String, List<ExtensionMemberDescriptor>> nameToDescriptors,
      Map<ExtensionMemberDescriptor, Class> descriptorToClass,
      Map<Reference, Extension> staticInteropClassesWithExtensions,
      TypeEnvironment typeEnvironment) {
    assert(js_interop.hasStaticInteropAnnotation(this));
    var classes = <Class>{};
    // Compute a map of all the possible descriptors available in this type and
    // the supertypes.
    void getAllDescriptors(Class cls) {
      if (classes.add(cls)) {
        if (staticInteropClassesWithExtensions.containsKey(cls.reference)) {
          for (var descriptor
              in staticInteropClassesWithExtensions[cls.reference]!.members) {
            if (!descriptor.isExternal || descriptor.isStatic) continue;
            // No need to handle external fields - they are transformed to
            // external getters/setters by the CFE.
            if (!descriptor.isGetter &&
                !descriptor.isSetter &&
                !descriptor.isMethod) {
              continue;
            }
            descriptorToClass[descriptor] = cls;
            nameToDescriptors
                .putIfAbsent(descriptor.name.text, () => [])
                .add(descriptor);
          }
        }
        cls.supers.forEach((Supertype supertype) {
          getAllDescriptors(supertype.classNode);
        });
      }
    }

    getAllDescriptors(this);

    InterfaceType getOnType(ExtensionMemberDescriptor desc) =>
        InterfaceType(descriptorToClass[desc]!, Nullability.nonNullable);

    bool isStrictSubtypeOf(InterfaceType s, InterfaceType t) {
      if (s.className == t.className) return false;
      return typeEnvironment.isSubtypeOf(
          s, t, SubtypeCheckMode.withNullabilities);
    }

    // Try and find the most specific member amongst duplicate names using
    // subtype checks.
    for (var name in nameToDescriptors.keys) {
      // The set of potential targets whose on-types are not strict subtypes of
      // any other target's on-type. As we iterate through the descriptors, this
      // invariant will hold true.
      var targets = <ExtensionMemberDescriptor>[];
      for (var descriptor in nameToDescriptors[name]!) {
        if (targets.isEmpty) {
          targets.add(descriptor);
        } else {
          var newOnType = getOnType(descriptor);
          // For each existing target, if the new descriptor's on-type is a
          // strict subtype of the target's on-type, then the new descriptor is
          // more specific. If any of the existing targets' on-types are a
          // strict subtype of the new descriptor's on-type, then the new
          // descriptor is never more specific, and therefore can be ignored.
          if (!targets.any(
              (target) => isStrictSubtypeOf(getOnType(target), newOnType))) {
            targets = [
              descriptor,
              // Not a supertype or a subtype, potential conflict or simply a
              // setter and getter.
              ...targets.where(
                  (target) => !isStrictSubtypeOf(newOnType, getOnType(target))),
            ];
          }
        }
      }
      nameToDescriptors[name] = targets;
    }
  }
}

extension ExtensionMemberDescriptorExtension on ExtensionMemberDescriptor {
  bool get isGetter => this.kind == ExtensionMemberKind.Getter;
  bool get isSetter => this.kind == ExtensionMemberKind.Setter;
  bool get isMethod => this.kind == ExtensionMemberKind.Method;

  bool get isExternal => (this.member.asProcedure).isExternal;
}
