// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:_fe_analyzer_shared/src/util/options.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/src/equivalence.dart';
import 'package:kernel/src/tool/command_line_util.dart';

void main(List<String> args) {
  ParsedOptions parsedOptions = ParsedOptions.parse(args, optionSpecification);

  CommandLineHelper.requireVariableArgumentCount([2], parsedOptions.arguments,
      () {
    print('''
Usage:

    dart check_equivalence.dart [options] <dill1> <dill2>
''');
  });
  if (parsedOptions.arguments.length != 2) {
    exit(1);
  }

  bool unordered = Options.unordered.read(parsedOptions);
  bool unorderedLibraries =
      unordered || Options.unorderedLibraries.read(parsedOptions);
  bool unorderedLibraryDependencies =
      unordered || Options.unorderedLibraries.read(parsedOptions);
  bool unorderedAdditionalExports =
      unordered || Options.unorderedLibraries.read(parsedOptions);
  bool unorderedParts =
      unordered || Options.unorderedLibraries.read(parsedOptions);
  bool unorderedTypedefs =
      unordered || Options.unorderedLibraries.read(parsedOptions);
  bool unorderedClasses =
      unordered || Options.unorderedLibraries.read(parsedOptions);
  bool unorderedMembers =
      unordered || Options.unorderedMembers.read(parsedOptions);
  bool unorderedFields =
      unorderedMembers || Options.unorderedFields.read(parsedOptions);
  bool unorderedProcedures =
      unorderedMembers || Options.unorderedProcedures.read(parsedOptions);
  bool unorderedConstructors =
      unorderedMembers || Options.unorderedConstructors.read(parsedOptions);
  bool unorderedAnnotations =
      unordered || Options.unorderedAnnotations.read(parsedOptions);

  Component dill1 = CommandLineHelper.tryLoadDill(parsedOptions.arguments[0]);
  Component dill2 = CommandLineHelper.tryLoadDill(parsedOptions.arguments[1]);
  EquivalenceResult result = checkEquivalence(dill1, dill2,
      strategy: new Strategy(
          unorderedLibraries: unorderedLibraries,
          unorderedLibraryDependencies: unorderedLibraryDependencies,
          unorderedAdditionalExports: unorderedAdditionalExports,
          unorderedParts: unorderedParts,
          unorderedTypedefs: unorderedTypedefs,
          unorderedClasses: unorderedClasses,
          unorderedFields: unorderedFields,
          unorderedProcedures: unorderedProcedures,
          unorderedConstructors: unorderedConstructors,
          unorderedAnnotations: unorderedAnnotations));
  if (result.isEquivalent) {
    print('The dills are equivalent.');
  } else {
    print('Inequivalence found:');
    print(result);
  }
}

EquivalenceResult checkNodeEquivalence(
  Node node1,
  Node node2, {
  bool unorderedLibraries = false,
  bool unorderedLibraryDependencies = false,
  bool unorderedAdditionalExports = false,
  bool unorderedParts = false,
  bool unorderedTypedefs = false,
  bool unorderedClasses = false,
  bool unorderedFields = false,
  bool unorderedProcedures = false,
  bool unorderedConstructors = false,
  bool unorderedAnnotations = false,
}) {
  return checkEquivalence(node1, node2,
      strategy: new Strategy(
          unorderedLibraries: unorderedLibraries,
          unorderedLibraryDependencies: unorderedLibraryDependencies,
          unorderedAdditionalExports: unorderedAdditionalExports,
          unorderedParts: unorderedParts,
          unorderedTypedefs: unorderedTypedefs,
          unorderedClasses: unorderedClasses,
          unorderedFields: unorderedFields,
          unorderedProcedures: unorderedProcedures,
          unorderedConstructors: unorderedConstructors,
          unorderedAnnotations: unorderedAnnotations));
}

class Strategy extends EquivalenceStrategy {
  final bool unorderedLibraries;
  final bool unorderedLibraryDependencies;
  final bool unorderedAdditionalExports;
  final bool unorderedParts;
  final bool unorderedTypedefs;
  final bool unorderedClasses;
  final bool unorderedFields;
  final bool unorderedProcedures;
  final bool unorderedConstructors;
  final bool unorderedAnnotations;

  Strategy(
      {required this.unorderedLibraries,
      required this.unorderedLibraryDependencies,
      required this.unorderedAdditionalExports,
      required this.unorderedParts,
      required this.unorderedTypedefs,
      required this.unorderedClasses,
      required this.unorderedFields,
      required this.unorderedProcedures,
      required this.unorderedConstructors,
      required this.unorderedAnnotations});

  @override
  bool checkComponent_libraries(
      EquivalenceVisitor visitor, Component node, Component other) {
    if (unorderedLibraries) {
      return visitor.checkSets(node.libraries.toSet(), other.libraries.toSet(),
          visitor.matchNamedNodes, visitor.checkNodes, 'libraries');
    } else {
      return visitor.checkLists(
          node.libraries, other.libraries, visitor.checkNodes, 'libraries');
    }
  }

  @override
  bool checkLibrary_dependencies(
      EquivalenceVisitor visitor, Library node, Library other) {
    if (unorderedLibraryDependencies) {
      return visitor
          .checkSets(node.dependencies.toSet(), other.dependencies.toSet(),
              (LibraryDependency dependency1, LibraryDependency dependency2) {
        return visitor.matchReferences(dependency1.importedLibraryReference,
                dependency2.importedLibraryReference) &&
            dependency1.flags == dependency2.flags &&
            dependency1.name == dependency2.name &&
            dependency1.fileOffset == dependency2.fileOffset;
      }, visitor.checkNodes, 'dependencies');
    } else {
      return visitor.checkLists(node.dependencies, other.dependencies,
          visitor.checkNodes, 'dependencies');
    }
  }

  @override
  bool checkLibrary_parts(
      EquivalenceVisitor visitor, Library node, Library other) {
    if (unorderedParts) {
      return visitor.checkSets(node.parts.toSet(), other.parts.toSet(),
          (LibraryPart part1, LibraryPart part2) {
        return part1.partUri == part2.partUri;
      }, visitor.checkNodes, 'parts');
    } else {
      return visitor.checkLists(
          node.parts, other.parts, visitor.checkNodes, 'parts');
    }
  }

  @override
  bool checkLibrary_typedefs(
      EquivalenceVisitor visitor, Library node, Library other) {
    if (unorderedTypedefs) {
      return visitor.checkSets(node.typedefs.toSet(), other.typedefs.toSet(),
          visitor.matchNamedNodes, visitor.checkNodes, 'typedefs');
    } else {
      return visitor.checkLists(
          node.typedefs, other.typedefs, visitor.checkNodes, 'typedefs');
    }
  }

  @override
  bool checkLibrary_additionalExports(
      EquivalenceVisitor visitor, Library node, Library other) {
    if (unorderedAdditionalExports) {
      return visitor.checkSets(
          node.additionalExports.toSet(),
          other.additionalExports.toSet(),
          visitor.matchReferences,
          visitor.checkReferences,
          'additionalExports');
    } else {
      return visitor.checkLists(node.additionalExports, other.additionalExports,
          visitor.checkReferences, 'additionalExports');
    }
  }

  @override
  bool checkLibrary_classes(
      EquivalenceVisitor visitor, Library node, Library other) {
    if (unorderedClasses) {
      return visitor.checkSets(node.classes.toSet(), other.classes.toSet(),
          visitor.matchNamedNodes, visitor.checkNodes, 'classes');
    } else {
      return visitor.checkLists(
          node.classes, other.classes, visitor.checkNodes, 'classes');
    }
  }

  @override
  bool checkLibrary_fields(
      EquivalenceVisitor visitor, Library node, Library other) {
    if (unorderedFields) {
      return visitor.checkSets(node.fields.toSet(), other.fields.toSet(),
          visitor.matchNamedNodes, visitor.checkNodes, 'fields');
    } else {
      return visitor.checkLists(
          node.fields, other.fields, visitor.checkNodes, 'fields');
    }
  }

  @override
  bool checkLibrary_procedures(
      EquivalenceVisitor visitor, Library node, Library other) {
    if (unorderedProcedures) {
      return visitor.checkSets(
          node.procedures.toSet(),
          other.procedures.toSet(),
          visitor.matchNamedNodes,
          visitor.checkNodes,
          'procedures');
    } else {
      return visitor.checkLists(
          node.procedures, other.procedures, visitor.checkNodes, 'procedures');
    }
  }

  @override
  bool checkLibrary_annotations(
      EquivalenceVisitor visitor, Library node, Library other) {
    if (unorderedAnnotations) {
      return visitor.checkSets(
          node.annotations.toSet(),
          other.annotations.toSet(),
          _matchAnnotations,
          visitor.checkNodes,
          'annotations');
    } else {
      return visitor.checkLists(node.annotations, other.annotations,
          visitor.checkNodes, 'annotations');
    }
  }

  @override
  bool checkClass_fields(EquivalenceVisitor visitor, Class node, Class other) {
    if (unorderedFields) {
      return visitor.checkSets(node.fields.toSet(), other.fields.toSet(),
          visitor.matchNamedNodes, visitor.checkNodes, 'fields');
    } else {
      return visitor.checkLists(
          node.fields, other.fields, visitor.checkNodes, 'fields');
    }
  }

  @override
  bool checkClass_procedures(
      EquivalenceVisitor visitor, Class node, Class other) {
    if (unorderedProcedures) {
      return visitor.checkSets(
          node.procedures.toSet(),
          other.procedures.toSet(),
          visitor.matchNamedNodes,
          visitor.checkNodes,
          'procedures');
    } else {
      return visitor.checkLists(
          node.procedures, other.procedures, visitor.checkNodes, 'procedures');
    }
  }

  @override
  bool checkClass_constructors(
      EquivalenceVisitor visitor, Class node, Class other) {
    if (unorderedConstructors) {
      return visitor.checkSets(
          node.constructors.toSet(),
          other.constructors.toSet(),
          visitor.matchNamedNodes,
          visitor.checkNodes,
          'constructors');
    } else {
      return visitor.checkLists(node.constructors, other.constructors,
          visitor.checkNodes, 'constructors');
    }
  }

  @override
  bool checkClass_annotations(
      EquivalenceVisitor visitor, Class node, Class other) {
    if (unorderedAnnotations) {
      return visitor.checkSets(
          node.annotations.toSet(),
          other.annotations.toSet(),
          _matchAnnotations,
          visitor.checkNodes,
          'annotations');
    } else {
      return visitor.checkLists(node.annotations, other.annotations,
          visitor.checkNodes, 'annotations');
    }
  }

  @override
  bool checkExtension_annotations(
      EquivalenceVisitor visitor, Extension node, Extension other) {
    if (unorderedAnnotations) {
      return visitor.checkSets(
          node.annotations.toSet(),
          other.annotations.toSet(),
          _matchAnnotations,
          visitor.checkNodes,
          'annotations');
    } else {
      return visitor.checkLists(node.annotations, other.annotations,
          visitor.checkNodes, 'annotations');
    }
  }

  @override
  bool checkMember_annotations(
      EquivalenceVisitor visitor, Member node, Member other) {
    if (unorderedAnnotations) {
      return visitor.checkSets(
          node.annotations.toSet(),
          other.annotations.toSet(),
          _matchAnnotations,
          visitor.checkNodes,
          'annotations');
    } else {
      return visitor.checkLists(node.annotations, other.annotations,
          visitor.checkNodes, 'annotations');
    }
  }

  bool _matchAnnotations(Expression expression1, Expression expression2) {
    return expression1.runtimeType == expression2.runtimeType &&
        expression1.fileOffset == expression2.fileOffset;
  }
}

class Flags {
  static const String unordered = '--unordered';
  static const String unorderedLibraries = '--unordered-libraries';
  static const String unorderedLibraryDependencies =
      '--unordered-library-dependencies';
  static const String unorderedParts = '--unordered-parts';
  static const String unorderedAdditionalExports =
      '--unordered-additional-exports';
  static const String unorderedTypedefs = '--unordered-typedefs';
  static const String unorderedClasses = '--unordered-classes';
  static const String unorderedMembers = '--unordered-members';
  static const String unorderedFields = '--unordered-fields';
  static const String unorderedProcedures = '--unordered-procedures';
  static const String unorderedConstructors = '--unordered-constructors';
  static const String unorderedAnnotations = '--unordered-annotations';
}

class Options {
  static const Option<bool> unordered =
      const Option(Flags.unordered, const BoolValue(false));
  static const Option<bool> unorderedLibraries =
      const Option(Flags.unorderedLibraries, const BoolValue(false));
  static const Option<bool> unorderedLibraryDependencies =
      const Option(Flags.unorderedLibraryDependencies, const BoolValue(false));
  static const Option<bool> unorderedParts =
      const Option(Flags.unorderedParts, const BoolValue(false));
  static const Option<bool> unorderedAdditionalExports =
      const Option(Flags.unorderedAdditionalExports, const BoolValue(false));
  static const Option<bool> unorderedTypedefs =
      const Option(Flags.unorderedTypedefs, const BoolValue(false));
  static const Option<bool> unorderedClasses =
      const Option(Flags.unorderedClasses, const BoolValue(false));
  static const Option<bool> unorderedMembers =
      const Option(Flags.unorderedMembers, const BoolValue(false));
  static const Option<bool> unorderedFields =
      const Option(Flags.unorderedFields, const BoolValue(false));
  static const Option<bool> unorderedProcedures =
      const Option(Flags.unorderedProcedures, const BoolValue(false));
  static const Option<bool> unorderedConstructors =
      const Option(Flags.unorderedConstructors, const BoolValue(false));
  static const Option<bool> unorderedAnnotations =
      const Option(Flags.unorderedAnnotations, const BoolValue(false));
}

const List<Option> optionSpecification = [
  Options.unordered,
  Options.unorderedLibraries,
  Options.unorderedLibraryDependencies,
  Options.unorderedParts,
  Options.unorderedAdditionalExports,
  Options.unorderedTypedefs,
  Options.unorderedClasses,
  Options.unorderedMembers,
  Options.unorderedFields,
  Options.unorderedProcedures,
  Options.unorderedConstructors,
  Options.unorderedAnnotations,
];
