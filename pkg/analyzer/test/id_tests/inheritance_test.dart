// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:_fe_analyzer_shared/src/testing/id.dart';
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/null_safety_understanding_flag.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/analysis/testing_data.dart';
import 'package:analyzer/src/util/ast_data_extractor.dart';

import '../util/id_testing_helper.dart';

main(List<String> args) async {
  Directory dataDir = Directory.fromUri(Platform.script
      .resolve('../../../_fe_analyzer_shared/test/inheritance/data'));
  await NullSafetyUnderstandingFlag.enableNullSafetyTypes(() {
    return runTests<String>(dataDir,
        args: args,
        createUriForFileName: createUriForFileName,
        onFailure: onFailure,
        runTest:
            runTestFor(const _InheritanceDataComputer(), [analyzerNnbdConfig]),
        skipMap: {
          analyzerMarker: [
            // These are CFE-centric tests for an opt-in/opt-out sdk.
            'object_opt_in',
            'object_opt_out',
          ]
        });
  });
}

class _InheritanceDataComputer extends DataComputer<String> {
  const _InheritanceDataComputer();

  @override
  DataInterpreter<String> get dataValidator => const StringDataInterpreter();

  @override
  void computeUnitData(TestingData testingData, CompilationUnit unit,
      Map<Id, ActualData<String>> actualMap) {
    _InheritanceDataExtractor(unit.declaredElement.source.uri, actualMap)
        .run(unit);
  }

  @override
  bool get supportsErrors => true;

  @override
  String computeErrorData(TestConfig config, TestingData testingData, Id id,
      List<AnalysisError> errors) {
    return errors.map((e) => e.errorCode).join(',');
  }
}

class _InheritanceDataExtractor extends AstDataExtractor<String> {
  _InheritanceDataExtractor(Uri uri, Map<Id, ActualData<String>> actualMap)
      : super(uri, actualMap);

  @override
  String computeElementValue(Id id, Element element) {
    if (element is LibraryElement) {
      return 'nnbd=${element.isNonNullableByDefault}';
    }
    return null;
  }

  @override
  void computeForClass(Declaration node, Id id) {
    super.computeForClass(node, id);
    if (node is ClassDeclaration) {
      var cls = node.declaredElement;

      var getterNames = <Name>{};
      var setterNames = <Name>{};
      var methodNames = <Name>{};

      void collectMembers(InterfaceType type) {
        for (var element in type.accessors) {
          if (element.isGetter) {
            getterNames.add(Name(element));
          }
          if (element.isSetter) {
            setterNames.add(Name(element, isSetter: true));
          }
          var getter = element.declaration.correspondingGetter != null
              ? element.correspondingGetter
              : null;
          if (getter != null) {
            getterNames.add(Name(getter));
          }
          var setter = element.declaration.correspondingSetter != null
              ? element.correspondingSetter
              : null;
          if (setter != null) {
            setterNames.add(Name(setter, isSetter: true));
          }
        }
        for (var method in type.methods) {
          methodNames.add(Name(method));
        }
      }

      collectMembers(cls.thisType);
      for (var supertype in cls.allSupertypes) {
        collectMembers(supertype);
      }

      void registerMember(
          MemberId id, int offset, Object object, DartType type) {
        registerValue(uri, offset, id,
            type.getDisplayString(withNullability: true), object);
      }

      for (var getterName in getterNames) {
        var getter =
            cls.thisType.lookUpGetter2(getterName.text, getterName.library);
        if (getter != null) {
          ClassElement enclosingClass = getter.enclosingElement;
          if (enclosingClass.isDartCoreObject) continue;
          var id = MemberId.internal(getterName.text, className: cls.name);
          var offset =
              enclosingClass == cls ? getter.nameOffset : cls.nameOffset;
          registerMember(id, offset, getter, getter.returnType);
        }
      }

      for (var setterName in setterNames) {
        var setter =
            cls.thisType.lookUpSetter2(setterName.text, setterName.library);
        if (setter != null) {
          ClassElement enclosingClass = setter.enclosingElement;
          if (enclosingClass.isDartCoreObject) continue;
          var id =
              MemberId.internal('${setterName.text}=', className: cls.name);
          var offset =
              enclosingClass == cls ? setter.nameOffset : cls.nameOffset;
          registerMember(id, offset, setter, setter.type.parameters.first.type);
        }
      }

      for (var methodName in methodNames) {
        var method =
            cls.thisType.lookUpMethod2(methodName.text, methodName.library);
        if (method != null) {
          ClassElement enclosingClass = method.enclosingElement;
          if (enclosingClass.isDartCoreObject) continue;
          var id = MemberId.internal(methodName.text, className: cls.name);
          var offset =
              enclosingClass == cls ? method.nameOffset : cls.nameOffset;
          registerMember(id, offset, method, method.type);
        }
      }
    }
  }

  @override
  String computeNodeValue(Id id, AstNode node) {
    if (node is ClassDeclaration) {
      var cls = node.declaredElement;
      var supertypes = <String>[];
      supertypes.add(supertypeToString(cls.thisType));
      for (var supertype in cls.allSupertypes) {
        supertypes.add(supertypeToString(supertype));
      }
      supertypes.sort();
      return supertypes.join(',');
    }
    return null;
  }
}

String supertypeToString(InterfaceType type) {
  var sb = StringBuffer();
  sb.write(type.element.name);
  if (type.typeArguments.isNotEmpty) {
    sb.write('<');
    var comma = '';
    for (var typeArgument in type.typeArguments) {
      sb.write(comma);
      sb.write(typeArgument.getDisplayString(withNullability: true));
      comma = ', ';
    }
    sb.write('>');
  }
  return sb.toString();
}

class Name {
  final String text;
  final bool isPrivate;
  final LibraryElement library;

  Name.internal(this.text, this.isPrivate, this.library);

  factory Name(Element element, {bool isSetter = false}) {
    String name = element.name;
    if (isSetter) {
      if (!name.endsWith('=')) {
        throw UnsupportedError("Unexpected setter name '$name'");
      }
      name = name.substring(0, name.length - 1);
    }
    return Name.internal(name, element.isPrivate, element.library);
  }

  @override
  int get hashCode => isPrivate
      ? text.hashCode * 13 + library.hashCode * 17
      : text.hashCode * 13;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Name &&
        text == other.text &&
        isPrivate == other.isPrivate &&
        (!isPrivate || library == other.library);
  }

  @override
  String toString() => isPrivate ? '${library.name}::$text' : text;
}
