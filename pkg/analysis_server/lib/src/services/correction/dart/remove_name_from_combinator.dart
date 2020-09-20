// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveNameFromCombinator extends CorrectionProducer {
  String _combinatorKind;

  @override
  List<Object> get fixArguments => [_combinatorKind];

  @override
  FixKind get fixKind => DartFixKind.REMOVE_NAME_FROM_COMBINATOR;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    SourceRange rangeForCombinator(Combinator combinator) {
      var parent = combinator.parent;
      if (parent is NamespaceDirective) {
        var combinators = parent.combinators;
        if (combinators.length == 1) {
          var previousToken =
              combinator.parent.findPrevious(combinator.beginToken);
          if (previousToken != null) {
            return range.endEnd(previousToken, combinator);
          }
          return null;
        }
        var index = combinators.indexOf(combinator);
        if (index < 0) {
          return null;
        } else if (index == combinators.length - 1) {
          return range.endEnd(combinators[index - 1], combinator);
        }
        return range.startStart(combinator, combinators[index + 1]);
      }
      return null;
    }

    SourceRange rangeForNameInCombinator(
        Combinator combinator, SimpleIdentifier name) {
      NodeList<SimpleIdentifier> names;
      if (combinator is HideCombinator) {
        names = combinator.hiddenNames;
      } else if (combinator is ShowCombinator) {
        names = combinator.shownNames;
      } else {
        return null;
      }
      if (names.length == 1) {
        return rangeForCombinator(combinator);
      }
      var index = names.indexOf(name);
      if (index < 0) {
        return null;
      } else if (index == names.length - 1) {
        return range.endEnd(names[index - 1], name);
      }
      return range.startStart(name, names[index + 1]);
    }

    var node = coveredNode;
    if (node is SimpleIdentifier) {
      var parent = coveredNode.parent;
      if (parent is Combinator) {
        var rangeToRemove = rangeForNameInCombinator(parent, node);
        if (rangeToRemove == null) {
          return;
        }
        await builder.addDartFileEdit(file, (builder) {
          builder.addDeletion(rangeToRemove);
        });
        _combinatorKind = parent is HideCombinator ? 'hide' : 'show';
      }
    }
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static RemoveNameFromCombinator newInstance() => RemoveNameFromCombinator();
}
