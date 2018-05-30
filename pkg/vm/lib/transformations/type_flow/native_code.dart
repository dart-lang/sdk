// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Handling of native code and entry points.
library vm.transformations.type_flow.native_code;

import 'dart:convert' show json;
import 'dart:core' hide Type;
import 'dart:io' show File;

import 'package:kernel/ast.dart';
import 'package:kernel/library_index.dart' show LibraryIndex;
import 'package:kernel/core_types.dart' show CoreTypes;

// TODO(alexmarkov): Move findNativeName out of treeshaker and avoid dependency
// on unrelated transformation.
import 'package:kernel/transformations/treeshaker.dart' show findNativeName;

import 'calls.dart';
import 'types.dart';
import 'utils.dart';

abstract class EntryPointsListener {
  /// Add call by the given selector with arbitrary ('raw') arguments.
  void addRawCall(Selector selector);

  /// Sets the type of the given field.
  void addDirectFieldAccess(Field field, Type value);

  /// Add instantiation of the given class.
  ConcreteType addAllocatedClass(Class c);
}

/// Some entry points are not listed in any JSON file but are marked with the
/// `@pragma('vm.entry_point', ...)` annotation instead.
///
/// Currently Procedure`s (action "call") can be annotated in this way.
//
// TODO(sjindel): Support all types of entry points.
class PragmaEntryPointsVisitor extends RecursiveVisitor {
  final EntryPointsListener entryPoints;
  final CoreTypes coreTypes;

  PragmaEntryPointsVisitor(this.coreTypes, this.entryPoints);

  bool _definesRoot(InstanceConstant constant) {
    if (constant.classReference.node != coreTypes.pragmaClass) return false;

    Constant name = constant.fieldValues[coreTypes.pragmaName.reference];
    assertx(name != null);
    if (name is! StringConstant ||
        (name as StringConstant).value != "vm.entry_point") {
      return false;
    }

    Constant options = constant.fieldValues[coreTypes.pragmaOptions.reference];
    assertx(options != null);
    if (options is NullConstant) return true;
    return options is BoolConstant && options.value;
  }

  bool _annotationsDefineRoot(List<Expression> annotations) {
    for (var annotation in annotations) {
      if (annotation is ConstantExpression) {
        Constant constant = annotation.constant;
        if (constant is InstanceConstant) {
          if (_definesRoot(constant)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  @override
  visitClass(Class klass) {
    if (_annotationsDefineRoot(klass.annotations)) {
      entryPoints.addAllocatedClass(klass);
    }
    klass.visitChildren(this);
  }

  @override
  visitProcedure(Procedure proc) {
    if (_annotationsDefineRoot(proc.annotations)) {
      entryPoints.addRawCall(proc.isInstanceMember
          ? new InterfaceSelector(proc, callKind: CallKind.Method)
          : new DirectSelector(proc, callKind: CallKind.Method));
    }
  }
}

/// Provides insights into the behavior of native code.
class NativeCodeOracle {
  final Map<String, List<Map<String, dynamic>>> _nativeMethods =
      <String, List<Map<String, dynamic>>>{};
  final LibraryIndex _libraryIndex;
  final Set<Member> _membersReferencedFromNativeCode = new Set<Member>();

  NativeCodeOracle(this._libraryIndex);

  bool isMemberReferencedFromNativeCode(Member member) =>
      _membersReferencedFromNativeCode.contains(member);

  /// Simulate the execution of a native method by adding its entry points
  /// using [entryPointsListener]. Returns result type of the native method.
  Type handleNativeProcedure(
      Member member, EntryPointsListener entryPointsListener) {
    final String nativeName = findNativeName(member);
    Type returnType = null;

    final nativeActions = _nativeMethods[nativeName];

    if (nativeActions != null) {
      for (var action in nativeActions) {
        if (action['action'] == 'return') {
          final c = _libraryIndex.getClass(action['library'], action['class']);

          final concreteClass = entryPointsListener.addAllocatedClass(c);

          final nullable = action['nullable'];
          if (nullable == false) {
            returnType = concreteClass;
          } else if ((nullable == true) || (nullable == null)) {
            returnType = new Type.nullable(concreteClass);
          } else {
            throw 'Bad entry point: unexpected nullable: "$nullable" in $action';
          }
        } else {
          _addRoot(action, entryPointsListener);
        }
      }
    }

    if (returnType != null) {
      return returnType;
    } else {
      return new Type.fromStatic(member.function.returnType);
    }
  }

  void _addRoot(
      Map<String, String> rootDesc, EntryPointsListener entryPointsListener) {
    final String library = rootDesc['library'];
    final String class_ = rootDesc['class'];
    final String name = rootDesc['name'];
    final String action = rootDesc['action'];

    final libraryIndex = _libraryIndex;

    if ((action == 'create-instance') || ((action == null) && (name == null))) {
      if (name != null) {
        throw 'Bad entry point: unexpected "name" element in $rootDesc';
      }

      final Class cls = libraryIndex.getClass(library, class_);
      if (cls.isAbstract) {
        throw 'Bad entry point: abstract class listed in $rootDesc';
      }

      entryPointsListener.addAllocatedClass(cls);
    } else if ((action == 'call') ||
        (action == 'get') ||
        (action == 'set') ||
        ((action == null) && (name != null))) {
      if (name == null) {
        throw 'Bad entry point: expected "name" element in $rootDesc';
      }

      final String prefix = {
            'get': LibraryIndex.getterPrefix,
            'set': LibraryIndex.setterPrefix
          }[action] ??
          '';

      Member member;

      if (class_ != null) {
        final classDotPrefix = class_ + '.';
        if ((name == class_) || name.startsWith(classDotPrefix)) {
          // constructor
          if (action != 'call' && action != null) {
            throw 'Bad entry point: action "$action" is not applicable to'
                ' constructor in $rootDesc';
          }

          final constructorName =
              (name == class_) ? '' : name.substring(classDotPrefix.length);

          member = libraryIndex.getMember(library, class_, constructorName);
        } else {
          member = libraryIndex.tryGetMember(library, class_, prefix + name);
          if (member == null) {
            member = libraryIndex.getMember(library, class_, name);
          }
        }
      } else {
        member = libraryIndex.tryGetTopLevelMember(
            library, /* unused */ null, prefix + name);
        if (member == null) {
          member = libraryIndex.getTopLevelMember(library, name);
        }
      }

      assertx(member != null);

      CallKind callKind;

      if (action == null) {
        if ((member is Field) || ((member is Procedure) && member.isGetter)) {
          callKind = CallKind.PropertyGet;
        } else if ((member is Procedure) && member.isSetter) {
          callKind = CallKind.PropertySet;
        } else {
          callKind = CallKind.Method;
        }
      } else {
        callKind = const {
          'get': CallKind.PropertyGet,
          'set': CallKind.PropertySet,
          'call': CallKind.Method
        }[action];
      }

      assertx(callKind != null);

      final Selector selector = member.isInstanceMember
          ? new InterfaceSelector(member, callKind: callKind)
          : new DirectSelector(member, callKind: callKind);

      entryPointsListener.addRawCall(selector);

      if ((action == null) && (member is Field) && !member.isFinal) {
        Selector selector = member.isInstanceMember
            ? new InterfaceSelector(member, callKind: CallKind.PropertySet)
            : new DirectSelector(member, callKind: CallKind.PropertySet);

        entryPointsListener.addRawCall(selector);
      }

      _membersReferencedFromNativeCode.add(member);
    } else {
      throw 'Bad entry point: unrecognized action "$action" in $rootDesc';
    }
  }

  /// Reads JSON describing entry points and native methods from [jsonString].
  /// Adds all global entry points using [entryPointsListener].
  ///
  /// The format of the JSON descriptor is described in
  /// 'runtime/vm/compiler/aot/entry_points_json.md'.
  void processEntryPointsJSON(
      String jsonString, EntryPointsListener entryPointsListener) {
    final jsonObject = json.decode(jsonString);

    final roots = jsonObject['roots'];
    if (roots != null) {
      for (var root in roots) {
        _addRoot(new Map<String, String>.from(root), entryPointsListener);
      }
    }

    final nativeMethods = jsonObject['native-methods'];
    if (nativeMethods != null) {
      nativeMethods.forEach((name, actions) {
        _nativeMethods[name] = new List<Map<String, dynamic>>.from(
            actions.map((action) => new Map<String, dynamic>.from(action)));
      });
    }
  }

  /// Reads JSON files [jsonFiles] describing entry points and native methods.
  /// Adds all global entry points using [entryPointsListener].
  ///
  /// The format of the JSON descriptor is described in
  /// 'runtime/vm/compiler/aot/entry_points_json.md'.
  void processEntryPointsJSONFiles(
      List<String> jsonFiles, EntryPointsListener entryPointsListener) {
    for (var file in jsonFiles) {
      processEntryPointsJSON(
          new File(file).readAsStringSync(), entryPointsListener);
    }
  }
}
