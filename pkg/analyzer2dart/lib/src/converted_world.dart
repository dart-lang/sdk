// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer2dart.convertedWorld;

import 'dart:collection';

import 'package:analyzer/analyzer.dart';
import 'package:compiler/src/elements/elements.dart' as dart2js;
import 'package:analyzer/src/generated/element.dart' as analyzer;
import 'package:compiler/src/cps_ir/cps_ir_nodes.dart' as ir;

import 'closed_world.dart';
import 'element_converter.dart';
import 'cps_generator.dart';
import 'util.dart';

/// A [ClosedWorld] converted to the dart2js element model.
abstract class ConvertedWorld {
  Iterable<dart2js.LibraryElement> get libraries;
  Iterable<dart2js.AstElement> get resolvedElements;
  Iterable<dart2js.ClassElement> get instantiatedClasses;
  dart2js.FunctionElement get mainFunction;
  ir.Node getIr(dart2js.Element element);

}

class _ConvertedWorldImpl implements ConvertedWorld {
  final dart2js.FunctionElement mainFunction;
  Map<dart2js.AstElement, ir.Node> executableElements =
      new HashMap<dart2js.AstElement, ir.Node>();

  _ConvertedWorldImpl(this.mainFunction);

  // TODO(johnniwinther): Add all used libraries and all SDK libraries to the
  // set of libraries in the converted world.
  Iterable<dart2js.LibraryElement> get libraries => [mainFunction.library];

  Iterable<dart2js.AstElement> get resolvedElements => executableElements.keys;

  Iterable<dart2js.ClassElement> get instantiatedClasses => [];

  ir.Node getIr(dart2js.Element element) => executableElements[element];
}

ConvertedWorld convertWorld(ClosedWorld closedWorld) {
  ElementConverter converter = new ElementConverter();
  _ConvertedWorldImpl convertedWorld = new _ConvertedWorldImpl(
      converter.convertElement(closedWorld.mainFunction));

  void convert(analyzer.Element analyzerElement, AstNode node) {
    // Skip conversion of SDK sources since we don't generate code for it
    // anyway.
    if (analyzerElement.source.isInSystemLibrary) return;

    dart2js.AstElement dart2jsElement =
        converter.convertElement(analyzerElement);
    CpsElementVisitor visitor = new CpsElementVisitor(converter, node);
    ir.Node cpsNode = analyzerElement.accept(visitor);
    if (cpsNode != null) {
      convertedWorld.executableElements[dart2jsElement] = cpsNode;
    } else {
      String message =
         'No CPS node generated for $analyzerElement (${node.runtimeType}).';
      reportSourceMessage(analyzerElement.source, node, message);
      throw new UnimplementedError(message);
    }
  }

  closedWorld.executableElements.forEach(convert);
  closedWorld.variables.forEach(convert);
  closedWorld.fields.forEach(convert);

  return convertedWorld;
}
