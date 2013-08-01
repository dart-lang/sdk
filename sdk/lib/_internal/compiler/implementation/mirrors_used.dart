// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.mirrors_used;

import 'dart2jslib.dart' show
    Compiler,
    CompilerTask,
    Constant,
    ConstructedConstant,
    ListConstant,
    MessageKind,
    SourceString,
    StringConstant,
    TypeConstant;

import 'elements/elements.dart' show
    Element,
    LibraryElement,
    MetadataAnnotation,
    VariableElement;

import 'util/util.dart' show
    Link;

import 'dart_types.dart' show
    DartType;

import 'tree/tree.dart' show
    Import,
    LibraryTag;

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

  MirrorUsageAnalyzerTask(Compiler compiler)
      : super(compiler);

  void analyzeUsage(LibraryElement mainApp) {
    if (compiler.mirrorsLibrary == null) return;
    MirrorUsageAnalyzer analyzer = new MirrorUsageAnalyzer(compiler, this);
    measure(analyzer.run);
    List<String> symbols = analyzer.mergedMirrorUsage.symbols;
    List<Element> targets = analyzer.mergedMirrorUsage.targets;
    List<Element> metaTargets = analyzer.mergedMirrorUsage.metaTargets;
    compiler.backend.registerMirrorUsage(
        symbols == null ? null : new Set<String>.from(symbols),
        targets == null ? null : new Set<Element>.from(targets),
        metaTargets == null ? null : new Set<Element>.from(metaTargets));
    librariesWithUsage = analyzer.librariesWithUsage;
  }

  bool hasMirrorUsage(Element element) {
    return librariesWithUsage != null
        && librariesWithUsage.contains(element.getLibrary());
  }
}

class MirrorUsageAnalyzer {
  final Compiler compiler;
  final MirrorUsageAnalyzerTask task;
  final List<LibraryElement> wildcard;
  final Set<LibraryElement> librariesWithUsage;
  final Set<LibraryElement> librariesWithoutUsage;
  MirrorUsage mergedMirrorUsage;

  MirrorUsageAnalyzer(Compiler compiler, this.task)
      : compiler = compiler,
        wildcard = compiler.libraries.values.toList(),
        librariesWithUsage = new Set<LibraryElement>(),
        librariesWithoutUsage = new Set<LibraryElement>();

  void run() {
    Map<LibraryElement, List<MirrorUsage>> usageMap =
        collectMirrorsUsedAnnotation();
    propagateOverrides(usageMap);
    librariesWithoutUsage.removeAll(usageMap.keys);
    if (librariesWithoutUsage.isEmpty) {
      mergedMirrorUsage = mergeUsages(usageMap);
    } else {
      mergedMirrorUsage = new MirrorUsage(null, wildcard, null, null);
    }
  }

  Map<LibraryElement, List<MirrorUsage>> collectMirrorsUsedAnnotation() {
    Map<LibraryElement, List<MirrorUsage>> result =
        new Map<LibraryElement, List<MirrorUsage>>();
    for (LibraryElement library in compiler.libraries.values) {
      if (library.isInternalLibrary) continue;
      librariesWithoutUsage.add(library);
      for (LibraryTag tag in library.tags) {
        Import importTag = tag.asImport();
        if (importTag == null) continue;
        compiler.withCurrentElement(library, () {
          List<MirrorUsage> usages =
              mirrorsUsedOnLibraryTag(library, importTag);
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
    propagatedOverrides.forEach((LibraryElement overridden,
                                 List<MirrorUsage> overriddenUsages) {
      List<MirrorUsage> usages =
          usageMap.putIfAbsent(overridden, () => <MirrorUsage>[]);
      usages.addAll(overriddenUsages);
    });
  }

  List<MirrorUsage> mirrorsUsedOnLibraryTag(LibraryElement library,
                                            Import tag) {
    LibraryElement importedLibrary = library.getLibraryFromTag(tag);
    if (importedLibrary != compiler.mirrorsLibrary) {
      return null;
    }
    List<MirrorUsage> result = <MirrorUsage>[];
    for (MetadataAnnotation metadata in tag.metadata) {
      metadata.ensureResolved(compiler);
      Element element = metadata.value.computeType(compiler).element;
      if (element == compiler.mirrorsUsedClass) {
        try {
          MirrorUsage usage =
              new MirrorUsageBuilder(this, library).build(metadata.value);
          result.add(usage);
        } on BadMirrorsUsedAnnotation catch (e) {
          compiler.reportError(
              metadata, MessageKind.GENERIC, {'text': e.message});
        }
      }
    }
    return result;
  }

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

  MirrorUsage merge(MirrorUsage a, MirrorUsage b) {
    if (a.symbols == null && a.targets == null && a.metaTargets == null) {
      return b;
    } else if (
        b.symbols == null && b.targets == null && b.metaTargets == null) {
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
}

class MirrorUsage {
  final List<String> symbols;
  final List<Element> targets;
  final List<Element> metaTargets;
  final List<Element> override;

  MirrorUsage(this.symbols, this.targets, this.metaTargets, this.override);

  String toString() {
    return
        'MirrorUsage('
        'symbols = $symbols, '
        'targets = $targets, '
        'metaTargets = $metaTargets, '
        'override = $override'
        ')';

  }
}

class MirrorUsageBuilder {
  MirrorUsageAnalyzer analyzer;
  LibraryElement enclosingLibrary;

  MirrorUsageBuilder(this.analyzer, this.enclosingLibrary);

  Compiler get compiler => analyzer.compiler;

  MirrorUsage build(ConstructedConstant constant) {
    Map<Element, Constant> fields = constant.fieldElements;
    VariableElement symbolsField = compiler.mirrorsUsedClass.lookupLocalMember(
        const SourceString('symbols'));
    VariableElement targetsField = compiler.mirrorsUsedClass.lookupLocalMember(
        const SourceString('targets'));
    VariableElement metaTargetsField =
        compiler.mirrorsUsedClass.lookupLocalMember(
            const SourceString('metaTargets'));
    VariableElement overrideField = compiler.mirrorsUsedClass.lookupLocalMember(
        const SourceString('override'));
    List<String> symbols =
        convertToListOfStrings(
            convertConstantToUsageList(fields[symbolsField]));
    List<Element> targets =
        resolveUsageList(convertConstantToUsageList(fields[targetsField]));

    List<Element> metaTargets =
        resolveUsageList(convertConstantToUsageList(fields[metaTargetsField]));
    List<Element> override =
        resolveUsageList(convertConstantToUsageList(fields[overrideField]));
    return new MirrorUsage(symbols, targets, metaTargets, override);
  }

  List convertConstantToUsageList(Constant constant) {
    if (constant.isNull()) {
      return null;
    } else if (constant.isList()) {
      ListConstant list = constant;
      List result = [];
      for (Constant entry in list.entries) {
        if (entry.isString()) {
          StringConstant string = entry;
          result.add(string.value.slowToString());
        } else if (entry.isType()) {
          TypeConstant type = entry;
          result.add(type.representedType);
        } else {
          throw new BadMirrorsUsedAnnotation(
              'Expected a string or type, but got "$entry".');
        }
      }
      return result;
    } else if (constant.isType()) {
      TypeConstant type = constant;
      return [type.representedType];
    } else if (constant.isString()) {
      StringConstant string = constant;
      return
          string.value.slowToString().split(',').map((e) => e.trim()).toList();
    } else {
      throw new BadMirrorsUsedAnnotation(
          'Expected a string or a list of string, but got "$constant".');
    }
  }

  List<String> convertToListOfStrings(List list) {
    if (list == null) return null;
    List<String> result = new List<String>(list.length);
    int count = 0;
    for (var entry in list) {
      if (entry is! String) {
        throw new BadMirrorsUsedAnnotation(
            'Expected a string, but got "$entry"');
      }
      result[count++] = entry;
    }
    return result;
  }

  List<Element> resolveUsageList(List list) {
    if (list == null) return null;
    if (list.length == 1 && list[0] == '*') {
      return analyzer.wildcard;
    }
    List<Element> result = <Element>[];
    for (var entry in list) {
      if (entry is DartType) {
        DartType type = entry;
        result.add(type.element);
      } else {
        String string = entry;
        for (LibraryElement l in compiler.libraries.values) {
          if (l.hasLibraryName()) {
            String libraryName = l.getLibraryOrScriptName();
            if (string == libraryName || string.startsWith('$libraryName.')) {
              result.add(l);
              break;
            }
          }
        }
      }
    }
    return result;
  }
}

class BadMirrorsUsedAnnotation {
  final String message;
  BadMirrorsUsedAnnotation(this.message);
}
