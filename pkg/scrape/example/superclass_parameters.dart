// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:analyzer/dart/ast/ast.dart';
import 'package:scrape/scrape.dart';

enum ArgumentMatch {
  noArguments,
  none,
  all,
  some,
  prefix,
  suffix,
  middle,
  noncontiguous
}

extension on ArgumentMatch {
  String get description {
    switch (this) {
      case ArgumentMatch.noArguments:
        return 'No arguments to match';
      case ArgumentMatch.none:
        return 'Matched none';
      case ArgumentMatch.all:
        return 'Matched all';
      case ArgumentMatch.some:
        return 'Matched some';
      case ArgumentMatch.prefix:
        return 'Matched prefix';
      case ArgumentMatch.suffix:
        return 'Matched suffix';
      case ArgumentMatch.middle:
        return 'Matched middle';
      case ArgumentMatch.noncontiguous:
        return 'Matched noncontiguous';
    }
  }
}

void main(List<String> arguments) {
  Scrape()
    ..addHistogram('Potential use')
    ..addHistogram('Individual arguments')
    ..addHistogram('Named arguments')
    ..addHistogram('Positional arguments')
    ..addHistogram('Argument pattern')
    ..addHistogram('Append super args')
    ..addHistogram('Prepend super args')
    ..addHistogram('Insert super args')
    ..addHistogram('Do not merge super args')
    ..addHistogram('No explicit super(), call unnamed')
    ..addHistogram('No explicit super(), call same name')
    ..addVisitor(() => SuperclassParameterVisitor())
    ..runCommandLine(arguments);
}

class SuperclassParameterVisitor extends ScrapeVisitor {
  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    // Whether the constructor might benefit from the feature at all.
    var initializer = _findSuper(node);
    if (initializer == null) {
      record('Potential use', 'No: No initializer');
      return;
    }

    if (initializer.argumentList.arguments.isEmpty) {
      record('Potential use', 'No: Empty super() argument list');
      return;
    }

    record('Potential use', 'Yes');

    // If we get here, we have a superclass constructor call with arguments.
    // See if any of them could use the feature.
    var positionalParamNames = node.parameters.parameters
        .where((param) => param.isPositional)
        .map((param) => param.identifier!.name)
        .toList();

    var namedParamNames = node.parameters.parameters
        .where((param) => param.isNamed)
        .map((param) => param.identifier!.name)
        .toSet();

    var matchedNamedArguments = 0;
    var unmatchedNamedArguments = 0;

    var lastPositionalParam = -1;
    var matchedIndexes = <int>[];
    var unmatchedPositionalArguments = 0;
    var positionalArgCount = 0;
    for (var i = 0; i < initializer.argumentList.arguments.length; i++) {
      var argument = initializer.argumentList.arguments[i];

      if (argument is NamedExpression) {
        var expression = argument.expression;
        if (expression is! SimpleIdentifier) {
          record('Individual arguments',
              'Named argument expression is not identifier');
          unmatchedNamedArguments++;
        } else if (argument.name.label.name != expression.name) {
          record('Individual arguments',
              'Named argument name does not match expression name');
          unmatchedNamedArguments++;
        } else if (!namedParamNames.contains(expression.name)) {
          record('Individual arguments',
              'Named argument does not match a parameter');
          unmatchedNamedArguments++;
        } else {
          record('Individual arguments', 'Argument matches a parameter');
          matchedNamedArguments++;
        }
      } else {
        positionalArgCount++;
        if (argument is! SimpleIdentifier) {
          record('Individual arguments',
              'Positional argument expression is not identifier');
          unmatchedPositionalArguments++;
        } else {
          // Start searching after the last matched positional parameter because
          // we don't allow reordering them. If two arguments are out of order,
          // that doesn't mean we can't use "super." at all, just that we can
          // only use it for *one* of those arguments.
          var index =
              positionalParamNames.indexOf(argument.name, lastPositionalParam);
          if (index == -1) {
            record('Individual arguments',
                'Positional argument does not match a parameter');
          } else {
            record('Individual arguments', 'Argument matches a parameter');
            lastPositionalParam = index;
            matchedIndexes.add(i);
          }
        }
      }
    }

    // Characterize the positional argument list.
    ArgumentMatch positionalMatch;
    if (unmatchedPositionalArguments == 0) {
      if (matchedIndexes.isEmpty) {
        positionalMatch = ArgumentMatch.noArguments;
      } else {
        positionalMatch = ArgumentMatch.all;
      }
    } else if (matchedIndexes.isEmpty) {
      positionalMatch = ArgumentMatch.none;
    } else {
      // If there is any unmatched argument before a matched one, then the
      // matched arguments are not all at the beginning.
      var matchedArePrefix = true;
      for (var i = 1; i < positionalArgCount; i++) {
        if (!matchedIndexes.contains(i - 1) && matchedIndexes.contains(i)) {
          matchedArePrefix = false;
          break;
        }
      }

      // If there is any unmatched argument after a matched one, then the
      // matched arguments are not all at the end.
      var matchedAreSuffix = true;
      for (var i = 0; i < positionalArgCount - 1; i++) {
        if (!matchedIndexes.contains(i + 1) && matchedIndexes.contains(i)) {
          matchedAreSuffix = false;
          break;
        }
      }

      // If any index between the first and last matched arg is not matched,
      // then the arguments are not contiguous.
      var matchedAreContiguous = true;
      if (matchedIndexes.isNotEmpty) {
        for (var i = matchedIndexes.first; i <= matchedIndexes.last; i++) {
          if (!matchedIndexes.contains(i)) {
            matchedAreContiguous = false;
            break;
          }
        }
      }

      if (!matchedAreContiguous) {
        positionalMatch = ArgumentMatch.noncontiguous;
      } else if (matchedArePrefix) {
        positionalMatch = ArgumentMatch.prefix;
      } else if (matchedAreSuffix) {
        positionalMatch = ArgumentMatch.suffix;
      } else {
        positionalMatch = ArgumentMatch.middle;
      }
    }

    record('Positional arguments', positionalMatch.description);

    // Characterize the named argument list.
    ArgumentMatch namedMatch;
    if (matchedNamedArguments == 0) {
      if (unmatchedNamedArguments == 0) {
        namedMatch = ArgumentMatch.noArguments;
      } else {
        namedMatch = ArgumentMatch.none;
      }
    } else {
      if (unmatchedNamedArguments == 0) {
        namedMatch = ArgumentMatch.all;
      } else {
        namedMatch = ArgumentMatch.some;
      }
    }

    record('Named arguments', namedMatch.description);

    var pattern = [
      for (var i = 0; i < positionalArgCount; i++)
        matchedIndexes.contains(i) ? 's' : '_',
      for (var i = 0; i < matchedNamedArguments; i++) ':s',
      for (var i = 0; i < unmatchedNamedArguments; i++) ':_',
    ].join(',');
    record('Argument pattern', '($pattern)');

    // If none of the arguments could be 'super.', then none of the proposals
    // apply.
    if (matchedIndexes.isEmpty && matchedNamedArguments == 0) return;

    var append = true;
    var prepend = true;
    var insert = true;
    var noMerge = true;
    var allParams = true;

    switch (positionalMatch) {
      case ArgumentMatch.noArguments:
      case ArgumentMatch.all:
        // OK.
        break;

      case ArgumentMatch.none:
        allParams = false;
        break;

      case ArgumentMatch.some:
        throw Exception('Should not get some for positional args.');

      case ArgumentMatch.prefix:
        append = false;
        noMerge = false;
        allParams = false;
        break;

      case ArgumentMatch.suffix:
        prepend = false;
        noMerge = false;
        allParams = false;
        break;

      case ArgumentMatch.middle:
        append = false;
        prepend = false;
        noMerge = false;
        allParams = false;
        break;

      case ArgumentMatch.noncontiguous:
        append = false;
        prepend = false;
        insert = false;
        noMerge = false;
        allParams = false;
        break;
    }

    switch (namedMatch) {
      case ArgumentMatch.noArguments:
      case ArgumentMatch.all:
        // OK.
        break;

      case ArgumentMatch.none:
      case ArgumentMatch.some:
        allParams = false;
        break;

      default:
        throw Exception('Unexpected match.');
    }

    record('Append super args', append ? 'Yes' : 'No');
    record('Prepend super args', prepend ? 'Yes' : 'No');
    record('Insert super args', insert ? 'Yes' : 'No');
    record('Do not merge super args', noMerge ? 'Yes' : 'No');

    var subName = _constructorName(node.name);
    var superName = _constructorName(initializer.constructorName);

    record('No explicit super(), call same name',
        (allParams && superName == subName) ? 'Yes' : 'No');

    record('No explicit super(), call unnamed',
        (allParams && superName == '(unnamed)') ? 'Yes' : 'No');
  }

  String _constructorName(SimpleIdentifier? name) {
    if (name == null) return '(unnamed)';
    return name.name;
  }

  SuperConstructorInvocation? _findSuper(ConstructorDeclaration node) {
    for (var initializer in node.initializers) {
      if (initializer is SuperConstructorInvocation) {
        return initializer;
      }
    }

    return null;
  }
}
