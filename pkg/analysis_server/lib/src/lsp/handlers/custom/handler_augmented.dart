// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart' hide Element;
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/custom/abstract_go_to.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';

class AugmentedHandler extends AbstractGoToHandler {
  AugmentedHandler(super.server);

  @override
  Method get handlesMessage => CustomMethods.augmented;

  @override
  bool get requiresTrustedCaller => false;

  @override
  Either2<Location?, List<Location>> findRelatedLocations(
      Element element,
      ResolvedLibraryResult libraryResult,
      ResolvedUnitResult unit,
      String? prefix) {
    // Although the base class supports returning multiple elements, this
    // handler is documented to only return a single element.
    // Changing this to return a list could be a breaking change for
    // clients.
    return Either2.t1(elementToLocation(switch (element) {
      ExecutableElement element => element.augmentationTarget,
      InstanceElement element => element.augmentationTarget,
      PropertyInducingElement element => element.augmentationTarget,
      _ => null,
    }));
  }
}
