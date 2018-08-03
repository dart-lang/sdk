// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:meta/meta.dart';

/**
 * An object used to merge partial lists of results that were contributed by
 * plugins.
 *
 * All of the methods in this class assume that the contributions from the
 * analysis server are the first partial result in the list of partial results
 * to be merged.
 */
class ResultMerger {
  /**
   * Return a list of fixes composed by merging the lists of fixes in the
   * [partialResultList].
   *
   * The resulting list of fixes will contain exactly one fix for every analysis
   * error for which there are fixes. If two or more plugins contribute the same
   * fix for a given error, the resulting list will contain duplications.
   */
  List<plugin.AnalysisErrorFixes> mergeAnalysisErrorFixes(
      List<List<plugin.AnalysisErrorFixes>> partialResultList) {
    /**
     * Return a key encoding the unique attributes of the given [error].
     */
    String computeKey(AnalysisError error) {
      StringBuffer buffer = new StringBuffer();
      buffer.write(error.location.offset);
      buffer.write(';');
      buffer.write(error.code);
      buffer.write(';');
      buffer.write(error.message);
      buffer.write(';');
      buffer.write(error.correction);
      return buffer.toString();
    }

    int count = partialResultList.length;
    if (count == 0) {
      return <plugin.AnalysisErrorFixes>[];
    } else if (count == 1) {
      return partialResultList[0];
    }
    Map<String, plugin.AnalysisErrorFixes> fixesMap =
        <String, plugin.AnalysisErrorFixes>{};
    for (plugin.AnalysisErrorFixes fix in partialResultList[0]) {
      fixesMap[computeKey(fix.error)] = fix;
    }
    for (int i = 1; i < count; i++) {
      for (plugin.AnalysisErrorFixes fix in partialResultList[i]) {
        String key = computeKey(fix.error);
        plugin.AnalysisErrorFixes mergedFix = fixesMap[key];
        if (mergedFix == null) {
          fixesMap[key] = fix;
        } else {
          // If more than two plugins contribute fixes for the same error, this
          // will result in extra copy operations.
          List<plugin.PrioritizedSourceChange> mergedChanges =
              mergedFix.fixes.toList();
          mergedChanges.addAll(fix.fixes);
          plugin.AnalysisErrorFixes copiedFix = new plugin.AnalysisErrorFixes(
              mergedFix.error,
              fixes: mergedChanges);
          fixesMap[key] = copiedFix;
        }
      }
    }
    List<plugin.AnalysisErrorFixes> mergedFixes = fixesMap.values.toList();
    for (plugin.AnalysisErrorFixes fixes in mergedFixes) {
      fixes.fixes.sort((first, second) => first.priority - second.priority);
    }
    return mergedFixes;
  }

  /**
   * Return a list of errors composed by merging the lists of errors in the
   * [partialResultList].
   *
   * The resulting list will contain all of the analysis errors from all of the
   * plugins. If two or more plugins contribute the same error the resulting
   * list will contain duplications.
   */
  List<AnalysisError> mergeAnalysisErrors(
      List<List<AnalysisError>> partialResultList) {
    // TODO(brianwilkerson) Consider merging duplicate errors (same code,
    // location, and messages). If we do that, we should return the logical-or
    // of the hasFix fields from the merged errors.
    int count = partialResultList.length;
    if (count == 0) {
      return <AnalysisError>[];
    } else if (count == 1) {
      return partialResultList[0];
    }
    List<AnalysisError> mergedErrors = <AnalysisError>[];
    for (List<AnalysisError> partialResults in partialResultList) {
      mergedErrors.addAll(partialResults);
    }
    return mergedErrors;
  }

  /**
   * Return a list of suggestions composed by merging the lists of suggestions
   * in the [partialResultList].
   *
   * The resulting list will contain all of the suggestions from all of the
   * plugins. If two or more plugins contribute the same suggestion the
   * resulting list will contain duplications.
   */
  List<CompletionSuggestion> mergeCompletionSuggestions(
      List<List<CompletionSuggestion>> partialResultList) {
    int count = partialResultList.length;
    if (count == 0) {
      return <CompletionSuggestion>[];
    } else if (count == 1) {
      return partialResultList[0];
    }
    List<CompletionSuggestion> mergedSuggestions = <CompletionSuggestion>[];
    for (List<CompletionSuggestion> partialResults in partialResultList) {
      mergedSuggestions.addAll(partialResults);
    }
    return mergedSuggestions;
  }

  /**
   * Return a list of regions composed by merging the lists of regions in the
   * [partialResultList].
   *
   * The resulting list will contain all of the folding regions from all of the
   * plugins. If a plugin contributes a folding region that overlaps a region
   * from a previous plugin, the overlapping region will be omitted. (For these
   * purposes, if either region is fully contained within the other they are not
   * considered to be overlapping.)
   */
  List<FoldingRegion> mergeFoldingRegions(
      List<List<FoldingRegion>> partialResultList) {
    int count = partialResultList.length;
    if (count == 0) {
      return <FoldingRegion>[];
    } else if (count == 1) {
      return partialResultList[0];
    }
    List<FoldingRegion> mergedRegions = partialResultList[0].toList();

    /**
     * Return `true` if the [newRegion] does not overlap any of the regions in
     * the collection of [mergedRegions].
     */
    bool isNonOverlapping(FoldingRegion newRegion) {
      int newStart = newRegion.offset;
      int newEnd = newStart + newRegion.length;
      for (FoldingRegion existingRegion in mergedRegions) {
        int existingStart = existingRegion.offset;
        int existingEnd = existingStart + existingRegion.length;
        if (overlaps(newStart, newEnd, existingStart, existingEnd,
            allowNesting: true)) {
          return false;
        }
      }
      return true;
    }

    for (int i = 1; i < count; i++) {
      List<FoldingRegion> partialResults = partialResultList[i];
      for (FoldingRegion region in partialResults) {
        if (isNonOverlapping(region)) {
          mergedRegions.add(region);
        }
      }
    }
    return mergedRegions;
  }

  /**
   * Return a list of regions composed by merging the lists of regions in the
   * [partialResultList].
   *
   * The resulting list will contain all of the highlight regions from all of
   * the plugins. If two or more plugins contribute the same highlight region
   * the resulting list will contain duplications.
   */
  List<HighlightRegion> mergeHighlightRegions(
      List<List<HighlightRegion>> partialResultList) {
    int count = partialResultList.length;
    if (count == 0) {
      return <HighlightRegion>[];
    } else if (count == 1) {
      return partialResultList[0];
    }
    List<HighlightRegion> mergedRegions = <HighlightRegion>[];
    for (List<HighlightRegion> partialResults in partialResultList) {
      mergedRegions.addAll(partialResults);
    }
    return mergedRegions;
  }

  /**
   * Return kythe entry result parameters composed by merging the parameters in
   * the [partialResultList].
   *
   * The resulting list will contain all of the kythe entries from all of the
   * plugins. If a plugin contributes a kythe entry that is the same as the
   * entry from a different plugin, the entry will appear twice in the list.
   */
  KytheGetKytheEntriesResult mergeKytheEntries(
      List<KytheGetKytheEntriesResult> partialResultList) {
    List<KytheEntry> mergedEntries = <KytheEntry>[];
    Set<String> mergedFiles = new Set<String>();
    for (KytheGetKytheEntriesResult partialResult in partialResultList) {
      mergedEntries.addAll(partialResult.entries);
      mergedFiles.addAll(partialResult.files);
    }
    return new KytheGetKytheEntriesResult(mergedEntries, mergedFiles.toList());
  }

  /**
   * Return navigation notification parameters composed by merging the
   * parameters in the [partialResultList].
   *
   * The resulting list will contain all of the navigation regions from all of
   * the plugins. If a plugin contributes a navigation region that overlaps a
   * region from a previous plugin, the overlapping region will be omitted. (For
   * these purposes, nested regions are considered to be overlapping.)
   */
  AnalysisNavigationParams mergeNavigation(
      List<AnalysisNavigationParams> partialResultList) {
    int count = partialResultList.length;
    if (count == 0) {
      return null;
    } else if (count == 1) {
      return partialResultList[0];
    }
    AnalysisNavigationParams base = partialResultList[0];
    String file = base.file;
    List<NavigationRegion> mergedRegions = base.regions.toList();
    List<NavigationTarget> mergedTargets = base.targets.toList();
    List<String> mergedFiles = base.files.toList();

    /**
     * Return `true` if the [newRegion] does not overlap any of the regions in
     * the collection of [mergedRegions].
     */
    bool isNonOverlapping(NavigationRegion newRegion) {
      int newStart = newRegion.offset;
      int newEnd = newStart + newRegion.length;
      for (NavigationRegion mergedRegion in mergedRegions) {
        int mergedStart = mergedRegion.offset;
        int mergedEnd = mergedStart + mergedRegion.length;
        if (overlaps(newStart, newEnd, mergedStart, mergedEnd)) {
          return false;
        }
      }
      return true;
    }

    /**
     * Return the index of the region in the collection of [mergedRegions] that
     * covers exactly the same region as the [newRegion], or `-1` if there is no
     * such region.
     */
    int matchingRegion(newRegion) {
      int newOffset = newRegion.offset;
      int newLength = newRegion.length;
      for (int i = 0; i < mergedRegions.length; i++) {
        NavigationRegion mergedRegion = mergedRegions[i];
        if (newOffset == mergedRegion.offset &&
            newLength == mergedRegion.length) {
          return i;
        }
      }
      return -1;
    }

    for (int i = 1; i < count; i++) {
      // For now we take the optimistic approach of assuming that most or all of
      // the regions will not overlap and that we therefore don't need to remove
      // any unreferenced files or targets from the lists. If that isn't true
      // then this could result in server sending more data to the client than
      // is necessary.
      AnalysisNavigationParams result = partialResultList[i];
      List<NavigationRegion> regions = result.regions;
      List<NavigationTarget> targets = result.targets;
      List<String> files = result.files;
      //
      // Merge the file data.
      //
      Map<int, int> fileMap = <int, int>{};
      for (int j = 0; j < files.length; j++) {
        String file = files[j];
        int index = mergedFiles.indexOf(file);
        if (index < 0) {
          index = mergedFiles.length;
          mergedFiles.add(file);
        }
        fileMap[j] = index;
      }
      //
      // Merge the target data.
      //
      Map<int, int> targetMap = <int, int>{};
      for (int j = 0; j < targets.length; j++) {
        NavigationTarget target = targets[j];
        int newIndex = fileMap[target.fileIndex];
        if (target.fileIndex != newIndex) {
          target = new NavigationTarget(target.kind, newIndex, target.offset,
              target.length, target.startLine, target.startColumn);
        }
        int index = mergedTargets.indexOf(target);
        if (index < 0) {
          index = mergedTargets.length;
          mergedTargets.add(target);
        }
        targetMap[j] = index;
      }
      //
      // Merge the region data.
      //
      for (int j = 0; j < regions.length; j++) {
        NavigationRegion region = regions[j];
        List<int> newTargets = region.targets
            .map((int oldTarget) => targetMap[oldTarget])
            .toList();
        if (region.targets != newTargets) {
          region =
              new NavigationRegion(region.offset, region.length, newTargets);
        }
        int index = matchingRegion(region);
        if (index >= 0) {
          NavigationRegion mergedRegion = mergedRegions[index];
          List<int> mergedTargets = mergedRegion.targets;
          bool added = false;
          for (int target in region.targets) {
            if (!mergedTargets.contains(target)) {
              if (added) {
                mergedTargets.add(target);
              } else {
                //
                // This is potentially inefficient. If a merged region matches
                // regions from multiple plugins it will be copied multiple
                // times. The likelihood seems small enough to not warrant
                // optimizing this further.
                //
                mergedTargets = mergedTargets.toList();
                mergedTargets.add(target);
                mergedRegion = new NavigationRegion(
                    mergedRegion.offset, mergedRegion.length, mergedTargets);
                mergedRegions[index] = mergedRegion;
                added = true;
              }
            }
          }
          if (added) {
            mergedTargets.sort();
          }
        } else if (isNonOverlapping(region)) {
          mergedRegions.add(region);
        }
      }
    }
    return new AnalysisNavigationParams(
        file, mergedRegions, mergedTargets, mergedFiles);
  }

  /**
   * Return a list of occurrences composed by merging the lists of occurrences
   * in the [partialResultList].
   *
   * The resulting list of occurrences will contain exactly one occurrences for
   * every element for which there is at least one occurrences. If two or more
   * plugins contribute an occurrences for the same element, the resulting
   * occurrences for that element will include all of the locations from all of
   * the plugins without duplications.
   */
  List<Occurrences> mergeOccurrences(
      List<List<Occurrences>> partialResultList) {
    int count = partialResultList.length;
    if (count == 0) {
      return <Occurrences>[];
    } else if (count == 1) {
      return partialResultList[0];
    }
    Map<Element, Set<int>> elementMap = <Element, Set<int>>{};
    for (List<Occurrences> partialResults in partialResultList) {
      for (Occurrences occurances in partialResults) {
        Element element = occurances.element;
        Set<int> offsets =
            elementMap.putIfAbsent(element, () => new HashSet<int>());
        offsets.addAll(occurances.offsets);
      }
    }
    List<Occurrences> mergedOccurrences = <Occurrences>[];
    elementMap.forEach((Element element, Set<int> offsets) {
      List<int> sortedOffsets = offsets.toList();
      sortedOffsets.sort();
      mergedOccurrences
          .add(new Occurrences(element, sortedOffsets, element.name.length));
    });
    return mergedOccurrences;
  }

  /**
   * Return a list of outlines composed by merging the lists of outlines in the
   * [partialResultList].
   *
   * The resulting list of outlines will contain ...
   *
   * Throw an exception if any of the outlines are associated with an element
   * that does not have a location.
   *
   * Throw an exception if any outline has children that are also children of
   * another outline. No exception is thrown if a plugin contributes a top-level
   * outline that is a child of an outline contributed by a different plugin.
   */
  List<Outline> mergeOutline(List<List<Outline>> partialResultList) {
    /**
     * Return a key encoding the unique attributes of the given [element].
     */
    String computeKey(Element element) {
      Location location = element.location;
      if (location == null) {
        throw new StateError(
            'Elements in an outline are expected to have a location');
      }
      StringBuffer buffer = new StringBuffer();
      buffer.write(location.offset);
      buffer.write(';');
      buffer.write(element.kind.name);
      return buffer.toString();
    }

    int count = partialResultList.length;
    if (count == 0) {
      return <Outline>[];
    } else if (count == 1) {
      return partialResultList[0];
    }
    List<Outline> mergedOutlines = partialResultList[0].toList();
    Map<String, Outline> outlineMap = <String, Outline>{};
    Map<Outline, Outline> copyMap = <Outline, Outline>{};

    /**
     * Add the given [outline] and all of its children to the [outlineMap].
     */
    void addToMap(Outline outline) {
      String key = computeKey(outline.element);
      if (outlineMap.containsKey(key)) {
        // TODO(brianwilkerson) Decide how to handle this more gracefully.
        throw new StateError('Inconsistent outlines');
      }
      outlineMap[key] = outline;
      outline.children?.forEach(addToMap);
    }

    /**
     * Merge the children of the [newOutline] into the list of children of the
     * [mergedOutline].
     */
    void mergeChildren(Outline mergedOutline, Outline newOutline) {
      for (Outline newChild in newOutline.children) {
        Outline mergedChild = outlineMap[computeKey(newChild.element)];
        if (mergedChild == null) {
          // The [newChild] isn't in the existing list.
          Outline copiedOutline = copyMap.putIfAbsent(
              mergedOutline,
              () => new Outline(
                  mergedOutline.element,
                  mergedOutline.offset,
                  mergedOutline.length,
                  mergedOutline.codeOffset,
                  mergedOutline.codeLength,
                  children: mergedOutline.children.toList()));
          copiedOutline.children.add(newChild);
          addToMap(newChild);
        } else {
          mergeChildren(mergedChild, newChild);
        }
      }
    }

    mergedOutlines.forEach(addToMap);
    for (int i = 1; i < count; i++) {
      for (Outline outline in partialResultList[i]) {
        Outline mergedOutline = outlineMap[computeKey(outline.element)];
        if (mergedOutline == null) {
          // The [outline] does not correspond to any previously merged outline.
          mergedOutlines.add(outline);
          addToMap(outline);
        } else {
          // The [outline] corresponds to a previously merged outline, so we
          // just need to add its children to the merged outline's children.
          mergeChildren(mergedOutline, outline);
        }
      }
    }

    /**
     * Perform a depth first traversal of the outline structure rooted at the
     * given [outline] item, re-building each item if any of its children have
     * been updated by the merge process.
     */
    Outline traverse(Outline outline) {
      Outline copiedOutline = copyMap[outline];
      bool isCopied = copiedOutline != null;
      copiedOutline ??= outline;
      List<Outline> currentChildren = copiedOutline.children;
      if (currentChildren == null || currentChildren.isEmpty) {
        return outline;
      }
      List<Outline> updatedChildren =
          currentChildren.map((Outline child) => traverse(child)).toList();
      if (currentChildren != updatedChildren) {
        if (!isCopied) {
          return new Outline(
              copiedOutline.element,
              copiedOutline.offset,
              copiedOutline.length,
              copiedOutline.codeOffset,
              copiedOutline.codeLength,
              children: updatedChildren);
        }
        copiedOutline.children = updatedChildren;
        return copiedOutline;
      }
      return outline;
    }

    for (int i = 0; i < mergedOutlines.length; i++) {
      mergedOutlines[i] = traverse(mergedOutlines[i]);
    }
    return mergedOutlines;
  }

  /**
   * Return a list of source changes composed by merging the lists of source
   * changes in the [partialResultList].
   *
   * The resulting list will contain all of the source changes from all of the
   * plugins. If two or more plugins contribute the same source change the
   * resulting list will contain duplications.
   */
  List<plugin.PrioritizedSourceChange> mergePrioritizedSourceChanges(
      List<List<plugin.PrioritizedSourceChange>> partialResultList) {
    int count = partialResultList.length;
    if (count == 0) {
      return <plugin.PrioritizedSourceChange>[];
    } else if (count == 1) {
      return partialResultList[0];
    }
    List<plugin.PrioritizedSourceChange> mergedChanges =
        <plugin.PrioritizedSourceChange>[];
    for (List<plugin.PrioritizedSourceChange> partialResults
        in partialResultList) {
      mergedChanges.addAll(partialResults);
    }
    mergedChanges.sort((first, second) => first.priority - second.priority);
    return mergedChanges;
  }

  /**
   * Return a refactoring feedback composed by merging the refactoring feedbacks
   * in the [partialResultList].
   *
   * The content of the resulting feedback depends on the kind of feedbacks
   * being merged.
   *
   * Throw an exception if the refactoring feedbacks are of an unhandled type.
   *
   * The feedbacks in the [partialResultList] are expected to all be of the same
   * type. If that expectation is violated, and exception might be thrown.
   */
  RefactoringFeedback mergeRefactoringFeedbacks(
      List<RefactoringFeedback> feedbacks) {
    int count = feedbacks.length;
    if (count == 0) {
      return null;
    } else if (count == 1) {
      return feedbacks[0];
    }
    RefactoringFeedback first = feedbacks[0];
    if (first is ConvertGetterToMethodFeedback) {
      // The feedbacks are empty, so there's nothing to merge.
      return first;
    } else if (first is ConvertMethodToGetterFeedback) {
      // The feedbacks are empty, so there's nothing to merge.
      return first;
    } else if (first is ExtractLocalVariableFeedback) {
      List<int> coveringExpressionOffsets =
          first.coveringExpressionOffsets == null
              ? <int>[]
              : first.coveringExpressionOffsets.toList();
      List<int> coveringExpressionLengths =
          first.coveringExpressionLengths == null
              ? <int>[]
              : first.coveringExpressionLengths.toList();
      List<String> names = first.names.toList();
      List<int> offsets = first.offsets.toList();
      List<int> lengths = first.lengths.toList();
      for (int i = 1; i < count; i++) {
        ExtractLocalVariableFeedback feedback = feedbacks[i];
        // TODO(brianwilkerson) This doesn't ensure that the covering data is in
        // the right order and consistent.
        if (feedback.coveringExpressionOffsets != null) {
          coveringExpressionOffsets.addAll(feedback.coveringExpressionOffsets);
        }
        if (feedback.coveringExpressionLengths != null) {
          coveringExpressionLengths.addAll(feedback.coveringExpressionLengths);
        }
        for (String name in feedback.names) {
          if (!names.contains(name)) {
            names.add(name);
          }
        }
        offsets.addAll(feedback.offsets);
        lengths.addAll(feedback.lengths);
      }
      return new ExtractLocalVariableFeedback(names.toList(), offsets, lengths,
          coveringExpressionOffsets: (coveringExpressionOffsets.isEmpty
              ? null
              : coveringExpressionOffsets),
          coveringExpressionLengths: (coveringExpressionLengths.isEmpty
              ? null
              : coveringExpressionLengths));
    } else if (first is ExtractMethodFeedback) {
      int offset = first.offset;
      int length = first.length;
      String returnType = first.returnType;
      List<String> names = first.names.toList();
      bool canCreateGetter = first.canCreateGetter;
      List<RefactoringMethodParameter> parameters = first.parameters;
      List<int> offsets = first.offsets.toList();
      List<int> lengths = first.lengths.toList();
      for (int i = 1; i < count; i++) {
        ExtractMethodFeedback feedback = feedbacks[i];
        if (returnType.isEmpty) {
          returnType = feedback.returnType;
        }
        for (String name in feedback.names) {
          if (!names.contains(name)) {
            names.add(name);
          }
        }
        canCreateGetter = canCreateGetter && feedback.canCreateGetter;
        // TODO(brianwilkerson) This doesn't allow plugins to add parameters.
        // TODO(brianwilkerson) This doesn't check for duplicate offsets.
        offsets.addAll(feedback.offsets);
        lengths.addAll(feedback.lengths);
      }
      return new ExtractMethodFeedback(offset, length, returnType,
          names.toList(), canCreateGetter, parameters, offsets, lengths);
    } else if (first is InlineLocalVariableFeedback) {
      int occurrences = first.occurrences;
      for (int i = 1; i < count; i++) {
        occurrences +=
            (feedbacks[i] as InlineLocalVariableFeedback).occurrences;
      }
      return new InlineLocalVariableFeedback(first.name, occurrences);
    } else if (first is InlineMethodFeedback) {
      // There is nothing in the feedback that can reasonably be extended or
      // modified by other plugins.
      return first;
    } else if (first is MoveFileFeedback) {
      // The feedbacks are empty, so there's nothing to merge.
      return first;
    } else if (first is RenameFeedback) {
      // There is nothing in the feedback that can reasonably be extended or
      // modified by other plugins.
      return first;
    }
    throw new StateError(
        'Unsupported class of refactoring feedback: ${first.runtimeType}');
  }

  /**
   * Return a list of refactoring kinds composed by merging the lists of
   * refactoring kinds in the [partialResultList].
   *
   * The resulting list will contain all of the refactoring kinds from all of
   * the plugins, but will not contain duplicate elements.
   */
  List<RefactoringKind> mergeRefactoringKinds(
      List<List<RefactoringKind>> partialResultList) {
    int count = partialResultList.length;
    if (count == 0) {
      return <RefactoringKind>[];
    } else if (count == 1) {
      return partialResultList[0];
    }
    Set<RefactoringKind> mergedKinds = new HashSet<RefactoringKind>();
    for (List<RefactoringKind> partialResults in partialResultList) {
      mergedKinds.addAll(partialResults);
    }
    return mergedKinds.toList();
  }

  /**
   * Return the result for a getRefactorings request composed by merging the
   * results in the [partialResultList].
   *
   * The returned result will contain the concatenation of the initial, options,
   * and final problems. If two or more plugins produce the same problem, then
   * the resulting list of problems will contain duplications.
   *
   * The returned result will contain a merged list of refactoring feedbacks (as
   * defined by [mergeRefactoringFeedbacks]) and a merged list of source changes
   * (as defined by [mergeChanges]).
   *
   * The returned result will contain the concatenation of the potential edits.
   * If two or more plugins produce the same potential edit, then the resulting
   * list of potential edits will contain duplications.
   */
  EditGetRefactoringResult mergeRefactorings(
      List<EditGetRefactoringResult> partialResultList) {
    /**
     * Return the result of merging the given list of source [changes] into a
     * single source change.
     *
     * The resulting change will have the first non-null message and the first
     * non-null selection. The linked edit groups will be a concatenation of all
     * of the individual linked edit groups because there's no way to determine
     * when two such groups should be merged. The resulting list of edits will
     * be merged at the level of the file being edited, but will be a
     * concatenation of the individual edits within each file, even if multiple
     * plugins contribute duplicate or conflicting edits.
     */
    SourceChange mergeChanges(List<SourceChange> changes) {
      int count = changes.length;
      if (count == 0) {
        return null;
      } else if (count == 1) {
        return changes[0];
      }
      SourceChange first = changes[0];
      String message = first.message;
      Map<String, SourceFileEdit> editMap = <String, SourceFileEdit>{};
      for (SourceFileEdit edit in first.edits) {
        editMap[edit.file] = edit;
      }
      List<LinkedEditGroup> linkedEditGroups = first.linkedEditGroups.toList();
      Position selection = first.selection;
      for (int i = 1; i < count; i++) {
        SourceChange change = changes[i];
        for (SourceFileEdit edit in change.edits) {
          SourceFileEdit mergedEdit = editMap[edit.file];
          if (mergedEdit == null) {
            editMap[edit.file] = edit;
          } else {
            // This doesn't detect if multiple plugins contribute the same (or
            // conflicting) edits.
            List<SourceEdit> edits = mergedEdit.edits.toList();
            edits.addAll(edit.edits);
            editMap[edit.file] = new SourceFileEdit(
                mergedEdit.file, mergedEdit.fileStamp,
                edits: edits);
          }
        }
        linkedEditGroups.addAll(change.linkedEditGroups);
        message ??= change.message;
        selection ??= change.selection;
      }
      return new SourceChange(message,
          edits: editMap.values.toList(),
          linkedEditGroups: linkedEditGroups,
          selection: selection);
    }

    int count = partialResultList.length;
    if (count == 0) {
      return null;
    } else if (count == 1) {
      return partialResultList[0];
    }
    EditGetRefactoringResult result = partialResultList[0];
    List<RefactoringProblem> initialProblems = result.initialProblems.toList();
    List<RefactoringProblem> optionsProblems = result.optionsProblems.toList();
    List<RefactoringProblem> finalProblems = result.finalProblems.toList();
    List<RefactoringFeedback> feedbacks = <RefactoringFeedback>[];
    if (result.feedback != null) {
      feedbacks.add(result.feedback);
    }
    List<SourceChange> changes = <SourceChange>[];
    if (result.change != null) {
      changes.add(result.change);
    }
    List<String> potentialEdits = result.potentialEdits.toList();
    for (int i = 1; i < count; i++) {
      EditGetRefactoringResult result = partialResultList[1];
      initialProblems.addAll(result.initialProblems);
      optionsProblems.addAll(result.optionsProblems);
      finalProblems.addAll(result.finalProblems);
      if (result.feedback != null) {
        feedbacks.add(result.feedback);
      }
      if (result.change != null) {
        changes.add(result.change);
      }
      potentialEdits.addAll(result.potentialEdits);
    }
    return new EditGetRefactoringResult(
        initialProblems, optionsProblems, finalProblems,
        feedback: mergeRefactoringFeedbacks(feedbacks),
        change: mergeChanges(changes),
        potentialEdits: potentialEdits);
  }

  /**
   * Return a list of source changes composed by merging the lists of source
   * changes in the [partialResultList].
   *
   * The resulting list will contain all of the source changes from all of the
   * plugins. If two or more plugins contribute the same source change the
   * resulting list will contain duplications.
   */
  List<SourceChange> mergeSourceChanges(
      List<List<SourceChange>> partialResultList) {
    int count = partialResultList.length;
    if (count == 0) {
      return <SourceChange>[];
    } else if (count == 1) {
      return partialResultList[0];
    }
    List<SourceChange> mergedChanges = <SourceChange>[];
    for (List<SourceChange> partialResults in partialResultList) {
      mergedChanges.addAll(partialResults);
    }
    return mergedChanges;
  }

  /**
   * Return `true` if a region extending from [leftStart] (inclusive) to
   * [leftEnd] (exclusive) overlaps a region extending from [rightStart]
   * (inclusive) to [rightEnd] (exclusive). If [allowNesting] is `true`, then
   * the regions are allowed to overlap as long as one region is completely
   * nested within the other region.
   */
  @visibleForTesting
  bool overlaps(int leftStart, int leftEnd, int rightStart, int rightEnd,
      {bool allowNesting: false}) {
    if (leftEnd < rightStart || leftStart > rightEnd) {
      return false;
    }
    if (!allowNesting) {
      return true;
    }
    return !((leftStart <= rightStart && rightEnd <= leftEnd) ||
        (rightStart <= leftStart && leftEnd <= rightEnd));
  }
}
