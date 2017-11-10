// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Source information system mapping that attempts a semantic mapping between
/// offsets of JavaScript code points to offsets of Dart code points.

library dart2js.source_information.kernel;

import 'package:kernel/ast.dart' as ir;
import '../elements/entities.dart';
import 'source_information.dart';
import 'position_information.dart';

class KernelSourceInformationStrategy
    extends AbstractPositionSourceInformationStrategy<ir.Node> {
  const KernelSourceInformationStrategy();

  @override
  SourceInformationBuilder<ir.Node> createBuilderForContext(
      MemberEntity member) {
    return const KernelSourceInformationBuilder();
  }
}

/// [SourceInformationBuilder] that generates [PositionSourceInformation] from
/// Kernel nodes.
class KernelSourceInformationBuilder
    implements SourceInformationBuilder<ir.Node> {
  const KernelSourceInformationBuilder();

  @override
  SourceInformationBuilder forContext(MemberEntity member) => this;

  @override
  SourceInformation buildSwitchCase(ir.Node node) => null;

  @override
  SourceInformation buildSwitch(ir.Node node) => null;

  @override
  SourceInformation buildAs(ir.Node node) => null;

  @override
  SourceInformation buildIs(ir.Node node) => null;

  @override
  SourceInformation buildCatch(ir.Node node) => null;

  @override
  SourceInformation buildBinary(ir.Node node) => null;

  @override
  SourceInformation buildIndexSet(ir.Node node) => null;

  @override
  SourceInformation buildIndex(ir.Node node) => null;

  @override
  SourceInformation buildForInSet(ir.Node node) => null;

  @override
  SourceInformation buildForInCurrent(ir.Node node) => null;

  @override
  SourceInformation buildForInMoveNext(ir.Node node) => null;

  @override
  SourceInformation buildForInIterator(ir.Node node) => null;

  @override
  SourceInformation buildStringInterpolation(ir.Node node) => null;

  @override
  SourceInformation buildForeignCode(ir.Node node) => null;

  @override
  SourceInformation buildVariableDeclaration() => null;

  @override
  SourceInformation buildAssignment(ir.Node node) => null;

  @override
  SourceInformation buildThrow(ir.Node node) => null;

  @override
  SourceInformation buildNew(ir.Node node) => null;

  @override
  SourceInformation buildIf(ir.Node node) => null;

  @override
  SourceInformation buildCall(ir.Node receiver, ir.Node call) => null;

  @override
  SourceInformation buildGet(ir.Node node) => null;

  @override
  SourceInformation buildLoop(ir.Node node) => null;

  @override
  SourceInformation buildImplicitReturn(MemberEntity element) => null;

  @override
  SourceInformation buildReturn(ir.Node node) => null;

  @override
  SourceInformation buildCreate(ir.Node node) => null;

  @override
  SourceInformation buildGeneric(ir.Node node) => null;

  @override
  SourceInformation buildDeclaration(MemberEntity member) => null;
}
