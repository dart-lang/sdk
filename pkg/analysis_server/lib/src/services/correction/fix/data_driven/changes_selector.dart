// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/change.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/code_template.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/expression.dart';

/// An object that can select a single list of changes from among one or more
/// possible lists.
abstract class ChangesSelector {
  /// Return the list of changes that should be applied based on the [context].
  List<Change> getChanges(TemplateContext context);
}

/// A changes selector that uses boolean-valued conditions to select the list.
class ConditionalChangesSelector implements ChangesSelector {
  /// A table mapping the expressions to be evaluated to the changes that those
  /// conditions select.
  final Map<Expression, List<Change>> changeMap;

  /// Initialize a newly created conditional changes selector with the changes
  /// in the [changeMap].
  ConditionalChangesSelector(this.changeMap);

  @override
  List<Change> getChanges(TemplateContext context) {
    for (var entry in changeMap.entries) {
      var value = entry.key.evaluateIn(context);
      if (value is bool && value) {
        return entry.value;
      }
    }
    return null;
  }
}

/// A changes selector that has a single, unconditional list of changes.
class UnconditionalChangesSelector implements ChangesSelector {
  /// The list of changes to be returned.
  final List<Change> changes;

  /// Initialize a newly created changes selector to return the given list of
  /// [changes].
  UnconditionalChangesSelector(this.changes);

  @override
  List<Change> getChanges(TemplateContext context) {
    return changes;
  }
}
