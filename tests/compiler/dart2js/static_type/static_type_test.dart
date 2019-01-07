// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/diagnostics/diagnostic_listener.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/ir/cached_static_type.dart';
import 'package:compiler/src/kernel/element_map_impl.dart';
import 'package:compiler/src/kernel/kernel_strategy.dart';
import 'package:kernel/ast.dart' as ir;
import 'package:kernel/class_hierarchy.dart' as ir;
import 'package:kernel/core_types.dart' as ir;
import 'package:kernel/type_algebra.dart' as ir;
import 'package:kernel/type_environment.dart' as ir;
import '../equivalence/id_equivalence.dart';
import '../equivalence/id_equivalence_helper.dart';

main(List<String> args) {
  asyncTest(() async {
    Directory dataDir = new Directory.fromUri(Platform.script.resolve('data'));
    await checkTests(dataDir, new StaticTypeDataComputer(),
        args: args, testFrontend: true);
  });
}

class Tags {
  static const String typeUse = 'type';
  static const String staticUse = 'static';
  static const String dynamicUse = 'dynamic';
  static const String constantUse = 'constant';
  static const String runtimeTypeUse = 'runtimeType';
}

class StaticTypeDataComputer extends DataComputer<String> {
  ir.TypeEnvironment _typeEnvironment;

  ir.TypeEnvironment getTypeEnvironment(KernelToElementMapImpl elementMap) {
    if (_typeEnvironment == null) {
      ir.Component component = elementMap.env.mainComponent;
      _typeEnvironment = new ir.TypeEnvironment(
          new ir.CoreTypes(component), new ir.ClassHierarchy(component));
    }
    return _typeEnvironment;
  }

  /// Compute type inference data for [member] from kernel based inference.
  ///
  /// Fills [actualMap] with the data.
  @override
  void computeMemberData(Compiler compiler, MemberEntity member,
      Map<Id, ActualData<String>> actualMap,
      {bool verbose: false}) {
    KernelFrontEndStrategy frontendStrategy = compiler.frontendStrategy;
    KernelToElementMapImpl elementMap = frontendStrategy.elementMap;
    Map<ir.TreeNode, ir.DartType> staticTypeCache =
        elementMap.getCachedStaticTypes(member);
    ir.Member node = elementMap.getMemberNode(member);
    new StaticTypeIrComputer(
            compiler.reporter,
            actualMap,
            new CachedStaticType(
                getTypeEnvironment(elementMap), staticTypeCache))
        .run(node);
  }

  @override
  DataInterpreter<String> get dataValidator => const StringDataInterpreter();
}

class TypeTextVisitor implements ir.DartTypeVisitor1<void, StringBuffer> {
  const TypeTextVisitor();

  @override
  void defaultDartType(ir.DartType node, StringBuffer sb) {
    throw new UnsupportedError("Unhandled type $node (${node.runtimeType}).");
  }

  void writeType(ir.DartType type, StringBuffer sb) {
    type.accept1(this, sb);
  }

  void _writeTypes(List<ir.DartType> types, StringBuffer sb) {
    String comma = '';
    for (ir.DartType type in types) {
      sb.write(comma);
      writeType(type, sb);
      comma = ',';
    }
  }

  void _writeTypeArguments(List<ir.DartType> typeArguments, StringBuffer sb) {
    if (typeArguments.isNotEmpty) {
      sb.write('<');
      _writeTypes(typeArguments, sb);
      sb.write('>');
    }
  }

  @override
  void visitTypedefType(ir.TypedefType node, StringBuffer sb) {
    sb.write(node.typedefNode.name);
    _writeTypeArguments(node.typeArguments, sb);
  }

  @override
  void visitTypeParameterType(ir.TypeParameterType node, StringBuffer sb) {
    sb.write(node.parameter.name);
  }

  @override
  void visitFunctionType(ir.FunctionType node, StringBuffer sb) {
    writeType(node.returnType, sb);
    sb.write(' Function');
    if (node.typeParameters.isNotEmpty) {
      sb.write('<');
      String comma = '';
      for (ir.TypeParameter typeParameter in node.typeParameters) {
        sb.write(comma);
        sb.write(typeParameter.name);
        if (typeParameter is! ir.DynamicType) {
          sb.write(' extends ');
          writeType(typeParameter.bound, sb);
        }
        comma = ',';
      }
      sb.write('>');
    }
    sb.write('(');
    _writeTypes(
        node.positionalParameters.take(node.requiredParameterCount), sb);
    if (node.requiredParameterCount < node.positionalParameters.length) {
      if (node.requiredParameterCount > 0) {
        sb.write(',');
      }
      _writeTypes(
          node.positionalParameters.skip(node.requiredParameterCount), sb);
    }
    if (node.namedParameters.isNotEmpty) {
      if (node.positionalParameters.isNotEmpty) {
        sb.write(',');
      }
      String comma = '';
      for (ir.NamedType namedType in node.namedParameters) {
        sb.write(comma);
        sb.write(namedType.name);
        sb.write(': ');
        writeType(namedType.type, sb);
        comma = ',';
      }
    }
    sb.write(')');
  }

  @override
  void visitInterfaceType(ir.InterfaceType node, StringBuffer sb) {
    sb.write(node.classNode.name);
    _writeTypeArguments(node.typeArguments, sb);
  }

  @override
  void visitBottomType(ir.BottomType node, StringBuffer sb) {
    sb.write('<bottom>');
  }

  @override
  void visitVoidType(ir.VoidType node, StringBuffer sb) {
    sb.write('void');
  }

  @override
  void visitDynamicType(ir.DynamicType node, StringBuffer sb) {
    sb.write('dynamic');
  }

  @override
  void visitInvalidType(ir.InvalidType node, StringBuffer sb) {
    sb.write('<invalid>');
  }
}

/// IR visitor for computing inference data for a member.
class StaticTypeIrComputer extends IrDataExtractor<String> {
  final CachedStaticType staticTypeCache;

  StaticTypeIrComputer(DiagnosticReporter reporter,
      Map<Id, ActualData<String>> actualMap, this.staticTypeCache)
      : super(reporter, actualMap);

  String getStaticTypeValue(ir.DartType type) {
    StringBuffer sb = new StringBuffer();
    const TypeTextVisitor().writeType(type, sb);
    return sb.toString();
  }

  @override
  String computeMemberValue(Id id, ir.Member node) {
    return null;
  }

  @override
  String computeNodeValue(Id id, ir.TreeNode node) {
    if (node is ir.VariableGet || node is ir.MethodInvocation) {
      return getStaticTypeValue(node.accept(staticTypeCache));
    }
    return null;
  }
}
