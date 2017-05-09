// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.mirrors_used;

import 'common/tasks.dart' show CompilerTask;
import 'common.dart';
import 'compile_time_constants.dart' show ConstantCompiler;
import 'compiler.dart' show Compiler;
import 'constants/expressions.dart';
import 'constants/values.dart'
    show
        ConstantValue,
        ConstructedConstantValue,
        ListConstantValue,
        StringConstantValue,
        TypeConstantValue;
import 'elements/resolution_types.dart'
    show ResolutionDartType, ResolutionInterfaceType;
import 'elements/elements.dart'
    show
        ClassElement,
        Element,
        FieldElement,
        ImportElement,
        LibraryElement,
        MetadataAnnotation,
        ScopeContainerElement;
import 'elements/entities.dart';
import 'resolution/tree_elements.dart' show TreeElements;
import 'tree/tree.dart' show NamedArgument, NewExpression, Node;

/**
 * Compiler task that analyzes MirrorsUsed annotations.
 *
 * When importing 'dart:mirrors', it is possible to annotate the import with
 * MirrorsUsed annotation.  This is a way to declare what elements will be
 * reflected on at runtime.  Such elements, even they would normally be
 * discarded by the implicit tree-shaking algorithm must be preserved in the
 * final output.
 *
 * Since some libraries cannot tell exactly what they will be reflecting on, it
 * is possible for one library to specify a MirrorsUsed annotation that applies
 * to another library. For example:
 *
 * Mirror utility library that cannot tell what it is reflecting on:
 * library mirror_utils;
 * import 'dart:mirrors';
 * ...
 *
 * The main app which knows how it use the mirror utility library:
 * library main_app;
 * @MirrorsUsed(override='mirror_utils')
 * import 'dart:mirrors';
 * import 'mirror_utils.dart';
 * ...
 *
 * In this case, we say that @MirrorsUsed in main_app overrides @MirrorsUsed in
 * mirror_utils.
 *
 * It is possible to override all libraries using override='*'.  If multiple
 * catch-all overrides like this, they are merged together.
 *
 * It is possible for library "a" to declare that it overrides library "b", and
 * vice versa. In this case, both annotations will be discarded and the
 * compiler will emit a hint (that is, a warning that is not specified by the
 * language specification).
 *
 * After applying all the overrides, we can iterate over libraries that import
 * 'dart:mirrors'. If a library does not have an associated MirrorsUsed
 * annotation, then we have to discard all MirrorsUsed annotations and assume
 * everything can be reflected on.
 *
 * On the other hand, if all libraries importing dart:mirrors have a
 * MirrorsUsed annotation, these annotations are merged.
 *
 * MERGING MIRRORSUSED
 *
 * TBD.
 */
class MirrorUsageAnalyzerTask extends CompilerTask {
  Set<LibraryElement> librariesWithUsage;
  MirrorUsageAnalyzer analyzer;
  final Compiler compiler;

  MirrorUsageAnalyzerTask(Compiler compiler)
      : compiler = compiler,
        super(compiler.measurer) {
    analyzer = new MirrorUsageAnalyzer(compiler, this);
  }

  /// Collect @MirrorsUsed annotations in all libraries.  Called by the
  /// compiler after all libraries are loaded, but before resolution.
  void analyzeUsage(LibraryEntity mainApp) {
    if (mainApp == null || compiler.commonElements.mirrorsLibrary == null) {
      return;
    }
    measure(analyzer.run);
    List<String> symbols = analyzer.mergedMirrorUsage.symbols;
    List<Element> targets = analyzer.mergedMirrorUsage.targets;
    List<Element> metaTargets = analyzer.mergedMirrorUsage.metaTargets;
    compiler.backend.mirrorsDataBuilder.registerMirrorUsage(
        symbols == null ? null : new Set<String>.from(symbols),
        targets == null ? null : new Set<Element>.from(targets),
        metaTargets == null ? null : new Set<Element>.from(metaTargets));
    librariesWithUsage = analyzer.librariesWithUsage;
  }

  /// Is there a @MirrorsUsed annotation in the library of [element]?  Used by
  /// the resolver to suppress hints about using new Symbol or
  /// MirrorSystem.getName.
  bool hasMirrorUsage(Element element) {
    LibraryElement library = element.library;
    // Internal libraries always have implicit mirror usage.
    return library.isInternalLibrary ||
        (librariesWithUsage != null && librariesWithUsage.contains(library));
  }

  /// Call-back from the resolver to analyze MirrorsUsed annotations. The result
  /// is stored in [analyzer] and later used to compute
  /// [:analyzer.mergedMirrorUsage:].
  void validate(NewExpression node, TreeElements mapping) {
    for (Node argument in node.send.arguments) {
      NamedArgument named = argument.asNamedArgument();
      if (named == null) continue;
      ConstantCompiler constantCompiler = compiler.resolver.constantCompiler;
      ConstantValue value = constantCompiler.getConstantValue(
          constantCompiler.compileNode(named.expression, mapping));

      MirrorUsageBuilder builder = new MirrorUsageBuilder(analyzer,
          mapping.analyzedElement.library, named.expression, value, mapping);

      if (named.name.source == 'symbols') {
        analyzer.cachedStrings[value] =
            builder.convertConstantToUsageList(value, onlyStrings: true);
      } else if (named.name.source == 'targets') {
        analyzer.cachedElements[value] =
            builder.resolveUsageList(builder.convertConstantToUsageList(value));
      } else if (named.name.source == 'metaTargets') {
        analyzer.cachedElements[value] =
            builder.resolveUsageList(builder.convertConstantToUsageList(value));
      } else if (named.name.source == 'override') {
        analyzer.cachedElements[value] =
            builder.resolveUsageList(builder.convertConstantToUsageList(value));
      }
    }
  }
}

class MirrorUsageAnalyzer {
  final Compiler compiler;
  final MirrorUsageAnalyzerTask task;
  List<LibraryElement> wildcard;
  final Set<LibraryElement> librariesWithUsage;
  final Map<ConstantValue, List<String>> cachedStrings;
  final Map<ConstantValue, List<Element>> cachedElements;
  MirrorUsage mergedMirrorUsage;

  MirrorUsageAnalyzer(this.compiler, this.task)
      : librariesWithUsage = new Set<LibraryElement>(),
        cachedStrings = new Map<ConstantValue, List<String>>(),
        cachedElements = new Map<ConstantValue, List<Element>>();

  DiagnosticReporter get reporter => compiler.reporter;

  /// Collect and merge all @MirrorsUsed annotations. As a side-effect, also
  /// compute which libraries have the annotation (which is used by
  /// [MirrorUsageAnalyzerTask.hasMirrorUsage]).
  void run() {
    wildcard = compiler.libraryLoader.libraries.toList();
    Map<LibraryElement, List<MirrorUsage>> usageMap =
        collectMirrorsUsedAnnotation();
    propagateOverrides(usageMap);
    Set<LibraryElement> librariesWithoutUsage = new Set<LibraryElement>();
    usageMap.forEach((LibraryElement library, List<MirrorUsage> usage) {
      if (usage.isEmpty) librariesWithoutUsage.add(library);
    });
    if (librariesWithoutUsage.isEmpty) {
      mergedMirrorUsage = mergeUsages(usageMap);
    } else {
      mergedMirrorUsage = new MirrorUsage(null, null, null, null);
    }
  }

  /// Collect all @MirrorsUsed from all libraries and represent them as
  /// [MirrorUsage].
  Map<LibraryElement, List<MirrorUsage>> collectMirrorsUsedAnnotation() {
    Map<LibraryElement, List<MirrorUsage>> result =
        new Map<LibraryElement, List<MirrorUsage>>();
    for (LibraryElement library in compiler.libraryLoader.libraries) {
      if (library.isInternalLibrary) continue;
      for (ImportElement import in library.imports) {
        reporter.withCurrentElement(library, () {
          List<MirrorUsage> usages = mirrorsUsedOnLibraryTag(library, import);
          if (usages != null) {
            List<MirrorUsage> existing = result[library];
            if (existing != null) {
              existing.addAll(usages);
            } else {
              result[library] = usages;
            }
          }
        });
      }
    }
    return result;
  }

  /// Apply [MirrorUsage] with 'override' to libraries they override.
  void propagateOverrides(Map<LibraryElement, List<MirrorUsage>> usageMap) {
    Map<LibraryElement, List<MirrorUsage>> propagatedOverrides =
        new Map<LibraryElement, List<MirrorUsage>>();
    usageMap.forEach((LibraryElement library, List<MirrorUsage> usages) {
      for (MirrorUsage usage in usages) {
        List<Element> override = usage.override;
        if (override == null) continue;
        if (override == wildcard) {
          for (LibraryElement overridden in wildcard) {
            if (overridden != library) {
              List<MirrorUsage> overriddenUsages = propagatedOverrides
                  .putIfAbsent(overridden, () => <MirrorUsage>[]);
              overriddenUsages.add(usage);
            }
          }
        } else {
          for (Element overridden in override) {
            List<MirrorUsage> overriddenUsages = propagatedOverrides
                .putIfAbsent(overridden, () => <MirrorUsage>[]);
            overriddenUsages.add(usage);
          }
        }
      }
    });
    propagatedOverrides.forEach(
        (LibraryElement overridden, List<MirrorUsage> overriddenUsages) {
      List<MirrorUsage> usages =
          usageMap.putIfAbsent(overridden, () => <MirrorUsage>[]);
      usages.addAll(overriddenUsages);
    });
  }

  /// Find @MirrorsUsed annotations on the given import [tag] in [library]. The
  /// annotations are represented as [MirrorUsage].
  List<MirrorUsage> mirrorsUsedOnLibraryTag(
      LibraryElement library, ImportElement import) {
    LibraryElement importedLibrary = import.importedLibrary;
    if (importedLibrary != compiler.commonElements.mirrorsLibrary) {
      return null;
    }
    List<MirrorUsage> result = <MirrorUsage>[];
    for (MetadataAnnotation metadata in import.metadata) {
      metadata.ensureResolved(compiler.resolution);
      ConstantValue value =
          compiler.constants.getConstantValue(metadata.constant);
      ResolutionDartType type = value.getType(compiler.commonElements);
      Element element = type.element;
      if (element == compiler.commonElements.mirrorsUsedClass) {
        result.add(buildUsage(value));
      }
    }
    return result;
  }

  /// Merge all [MirrorUsage] instances across all libraries.
  MirrorUsage mergeUsages(Map<LibraryElement, List<MirrorUsage>> usageMap) {
    Set<MirrorUsage> usagesToMerge = new Set<MirrorUsage>();
    usageMap.forEach((LibraryElement library, List<MirrorUsage> usages) {
      librariesWithUsage.add(library);
      usagesToMerge.addAll(usages);
    });
    if (usagesToMerge.isEmpty) {
      return new MirrorUsage(null, wildcard, null, null);
    } else {
      MirrorUsage result = new MirrorUsage(null, null, null, null);
      for (MirrorUsage usage in usagesToMerge) {
        result = merge(result, usage);
      }
      return result;
    }
  }

  /// Merge [a] with [b]. The resulting [MirrorUsage] simply has the symbols,
  /// targets, and metaTargets of [a] and [b] concatenated. 'override' is
  /// ignored.
  MirrorUsage merge(MirrorUsage a, MirrorUsage b) {
    // TOOO(ahe): Should be an instance method on MirrorUsage.
    if (a.symbols == null && a.targets == null && a.metaTargets == null) {
      return b;
    } else if (b.symbols == null &&
        b.targets == null &&
        b.metaTargets == null) {
      return a;
    }
    // TODO(ahe): Test the following cases.
    List<String> symbols = a.symbols;
    if (symbols == null) {
      symbols = b.symbols;
    } else if (b.symbols != null) {
      symbols.addAll(b.symbols);
    }
    List<Element> targets = a.targets;
    if (targets == null) {
      targets = b.targets;
    } else if (targets != wildcard && b.targets != null) {
      targets.addAll(b.targets);
    }
    List<Element> metaTargets = a.metaTargets;
    if (metaTargets == null) {
      metaTargets = b.metaTargets;
    } else if (metaTargets != wildcard && b.metaTargets != null) {
      metaTargets.addAll(b.metaTargets);
    }
    return new MirrorUsage(symbols, targets, metaTargets, null);
  }

  /// Convert a [constant] to an instance of [MirrorUsage] using information
  /// that was resolved during [MirrorUsageAnalyzerTask.validate].
  MirrorUsage buildUsage(ConstructedConstantValue constant) {
    Map<FieldElement, ConstantValue> fields = constant.fields;
    ClassElement cls = compiler.commonElements.mirrorsUsedClass;
    FieldElement symbolsField = cls.lookupLocalMember('symbols');
    FieldElement targetsField = cls.lookupLocalMember('targets');
    FieldElement metaTargetsField = cls.lookupLocalMember('metaTargets');
    FieldElement overrideField = cls.lookupLocalMember('override');

    return new MirrorUsage(
        cachedStrings[fields[symbolsField]],
        cachedElements[fields[targetsField]],
        cachedElements[fields[metaTargetsField]],
        cachedElements[fields[overrideField]]);
  }
}

/// Used to represent a resolved MirrorsUsed constant.
class MirrorUsage {
  final List<String> symbols;
  final List<Element> targets;
  final List<Element> metaTargets;
  final List<Element> override;

  MirrorUsage(this.symbols, this.targets, this.metaTargets, this.override);

  String toString() {
    return 'MirrorUsage('
        'symbols = $symbols, '
        'targets = $targets, '
        'metaTargets = $metaTargets, '
        'override = $override'
        ')';
  }
}

class MirrorUsageBuilder {
  final MirrorUsageAnalyzer analyzer;
  final LibraryElement enclosingLibrary;
  final Spannable spannable;
  final ConstantValue constant;
  final TreeElements elements;

  MirrorUsageBuilder(this.analyzer, this.enclosingLibrary, this.spannable,
      this.constant, this.elements);

  Compiler get compiler => analyzer.compiler;

  DiagnosticReporter get reporter => analyzer.reporter;

  /// Convert a constant to a list of [String] and [Type] values. If the
  /// constant is a single [String], it is assumed to be a comma-separated list
  /// of qualified names. If the constant is a [Type] t, the result is [:[t]:].
  /// Otherwise, the constant is assumed to represent a list of strings (each a
  /// qualified name) and types, and such a list is constructed.  If
  /// [onlyStrings] is true, the returned list is a [:List<String>:] and any
  /// [Type] values are treated as an error (meaning that the value is ignored
  /// and a hint is emitted).
  List convertConstantToUsageList(ConstantValue constant,
      {bool onlyStrings: false}) {
    if (constant.isNull) {
      return null;
    } else if (constant.isList) {
      ListConstantValue list = constant;
      List result = onlyStrings ? <String>[] : [];
      for (ConstantValue entry in list.entries) {
        if (entry.isString) {
          StringConstantValue string = entry;
          result.add(string.primitiveValue);
        } else if (!onlyStrings && entry.isType) {
          TypeConstantValue type = entry;
          result.add(type.representedType);
        } else {
          Spannable node = positionOf(entry);
          MessageKind kind = onlyStrings
              ? MessageKind.MIRRORS_EXPECTED_STRING
              : MessageKind.MIRRORS_EXPECTED_STRING_OR_TYPE;
          reporter.reportHintMessage(
              node, kind, {'name': node, 'type': apiTypeOf(entry)});
        }
      }
      return result;
    } else if (!onlyStrings && constant.isType) {
      TypeConstantValue type = constant;
      return [type.representedType];
    } else if (constant.isString) {
      StringConstantValue string = constant;
      var iterable = string.primitiveValue.split(',').map((e) => e.trim());
      return onlyStrings ? new List<String>.from(iterable) : iterable.toList();
    } else {
      Spannable node = positionOf(constant);
      MessageKind kind = onlyStrings
          ? MessageKind.MIRRORS_EXPECTED_STRING_OR_LIST
          : MessageKind.MIRRORS_EXPECTED_STRING_TYPE_OR_LIST;
      reporter.reportHintMessage(
          node, kind, {'name': node, 'type': apiTypeOf(constant)});
      return null;
    }
  }

  /// Find the first non-implementation interface of constant.
  ResolutionDartType apiTypeOf(ConstantValue constant) {
    ResolutionDartType type = constant.getType(compiler.commonElements);
    LibraryElement library = type.element.library;
    if (type.isInterfaceType && library.isInternalLibrary) {
      ResolutionInterfaceType interface = type;
      ClassElement cls = type.element;
      cls.ensureResolved(compiler.resolution);
      for (ResolutionInterfaceType supertype in cls.allSupertypes) {
        if (supertype.isInterfaceType &&
            !supertype.element.library.isInternalLibrary) {
          return interface.asInstanceOf(supertype.element);
        }
      }
    }
    return type;
  }

  /// Convert a list of strings and types to a list of elements. Types are
  /// converted to their corresponding element, and strings are resolved as
  /// follows:
  ///
  /// First find the longest library name that is a prefix of the string, if
  /// there are none, resolve using [resolveExpression]. Otherwise, resolve the
  /// rest of the string using [resolveLocalExpression].
  List<Element> resolveUsageList(List list) {
    if (list == null) return null;
    if (list.length == 1 && list[0] == '*') {
      return analyzer.wildcard;
    }
    List<Element> result = <Element>[];
    for (var entry in list) {
      if (entry is ResolutionDartType) {
        ResolutionDartType type = entry;
        result.add(type.element);
      } else {
        String string = entry;
        LibraryElement libraryCandidate;
        String libraryNameCandidate;
        for (LibraryElement l in compiler.libraryLoader.libraries) {
          if (l.hasLibraryName) {
            String libraryName = l.libraryName;
            if (string == libraryName) {
              // Found an exact match.
              libraryCandidate = l;
              libraryNameCandidate = libraryName;
              break;
            } else if (string.startsWith('$libraryName.')) {
              if (libraryNameCandidate == null ||
                  libraryNameCandidate.length < libraryName.length) {
                // Found a better candidate
                libraryCandidate = l;
                libraryNameCandidate = libraryName;
              }
            }
          }
        }
        Element e;
        if (libraryNameCandidate == string) {
          e = libraryCandidate;
        } else if (libraryNameCandidate != null) {
          e = resolveLocalExpression(libraryCandidate,
              string.substring(libraryNameCandidate.length + 1).split('.'));
        } else {
          e = resolveExpression(string);
        }
        if (e != null) result.add(e);
      }
    }
    return result;
  }

  /// Resolve [expression] in [enclosingLibrary]'s import scope.
  Element resolveExpression(String expression) {
    List<String> identifiers = expression.split('.');
    Element element = enclosingLibrary.find(identifiers[0]);
    if (element == null) {
      reporter.reportHintMessage(
          spannable,
          MessageKind.MIRRORS_CANNOT_RESOLVE_IN_CURRENT_LIBRARY,
          {'name': expression});
      return null;
    } else {
      if (identifiers.length == 1) return element;
      return resolveLocalExpression(element, identifiers.sublist(1));
    }
  }

  /// Resolve [identifiers] in [element]'s local members.
  Element resolveLocalExpression(Element element, List<String> identifiers) {
    Element current = element;
    for (String identifier in identifiers) {
      Element e = findLocalMemberIn(current, identifier);
      if (e == null) {
        if (current.isLibrary) {
          LibraryElement library = current;
          reporter.reportHintMessage(
              spannable,
              MessageKind.MIRRORS_CANNOT_RESOLVE_IN_LIBRARY,
              {'name': identifiers[0], 'library': library.name});
        } else {
          reporter.reportHintMessage(
              spannable,
              MessageKind.MIRRORS_CANNOT_FIND_IN_ELEMENT,
              {'name': identifier, 'element': current.name});
        }
        return current;
      }
      current = e;
    }
    return current;
  }

  /// Helper method to lookup members in a [ScopeContainerElement]. If
  /// [element] is not a ScopeContainerElement, return null.
  Element findLocalMemberIn(Element element, String name) {
    if (element is ScopeContainerElement) {
      ScopeContainerElement scope = element;
      if (element.isClass) {
        ClassElement cls = element;
        cls.ensureResolved(compiler.resolution);
      }
      return scope.localLookup(name);
    }
    return null;
  }

  /// Attempt to find a [Spannable] corresponding to constant.
  Spannable positionOf(ConstantValue constant) {
    Node node;
    elements.forEachConstantNode((Node n, ConstantExpression c) {
      if (node == null && compiler.constants.getConstantValue(c) == constant) {
        node = n;
      }
    });
    if (node == null) {
      // TODO(ahe): Returning [spannable] here leads to confusing error
      // messages.  For example, consider:
      // @MirrorsUsed(targets: fisk)
      // import 'dart:mirrors';
      //
      // const fisk = const [main];
      //
      // main() {}
      //
      // The message is:
      // example.dart:1:23: Hint: Can't use 'fisk' here because ...
      // Did you forget to add quotes?
      // @MirrorsUsed(targets: fisk)
      //                       ^^^^
      //
      // Instead of saying 'fisk' should pretty print the problematic constant
      // value.
      return spannable;
    }
    return node;
  }
}
