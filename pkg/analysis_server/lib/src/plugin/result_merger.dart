// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:meta/meta.dart';

/// An object used to merge partial lists of results that were contributed by
/// plugins.
///
/// All of the methods in this class assume that the contributions from the
/// analysis server are the first partial result in the list of partial results
/// to be merged.
class ResultMerger {
  /// Return a list of fixes composed by merging the lists of fixes in the
  /// [partialResultList].
  ///
  /// The resulting list of fixes will contain exactly one fix for every
  /// analysis error for which there are fixes. If two or more plugins
  /// contribute the same fix for a given error, the resulting list will contain
  /// duplications.
  List<plugin.AnalysisErrorFixes> mergeAnalysisErrorFixes(
      List<List<plugin.AnalysisErrorFixes>> partialResultList) {
    /// Return a key encoding the unique attributes of the given [error].
    String computeKey(AnalysisError error) {
      var buffer = StringBuffer();
      buffer.write(error.location.offset);
      buffer.write(';');
      buffer.write(error.code);
      buffer.write(';');
      buffer.write(error.message);
      buffer.write(';');
      buffer.write(error.correction);
      return buffer.toString();
    }

    var count = partialResultList.length;
    if (count == 0) {
      return <plugin.AnalysisErrorFixes>[];
    } else if (count == 1) {
      return partialResultList[0];
    }
    var fixesMap = <String, plugin.AnalysisErrorFixes>{};
    for (var fix in partialResultList[0]) {
      fixesMap[computeKey(fix.error)] = fix;
    }
    for (var i = 1; i < count; i++) {
      for (var fix in partialResultList[i]) {
        var key = computeKey(fix.error);
        var mergedFix = fixesMap[key];
        if (mergedFix == null) {
          fixesMap[key] = fix;
        } else {
          // If more than two plugins contribute fixes for the same error, this
          // will result in extra copy operations.
          var mergedChanges = mergedFix.fixes.toList();
          mergedChanges.addAll(fix.fixes);
          var copiedFix =
              plugin.AnalysisErrorFixes(mergedFix.error, fixes: mergedChanges);
          fixesMap[key] = copiedFix;
        }
      }
    }
    var mergedFixes = fixesMap.values.toList();
    for (var fixes in mergedFixes) {
      fixes.fixes.sort((first, second) => first.priority - second.priority);
    }
    return mergedFixes;
  }

  /// Return a list of errors composed by merging the lists of errors in the
  /// [partialResultList].
  ///
  /// The resulting list will contain all of the analysis errors from all of the
  /// plugins. If two or more plugins contribute the same error the resulting
  /// list will contain duplications.
  List<AnalysisError> mergeAnalysisErrors(
      List<List<AnalysisError>> partialResultList) {
    // TODO(brianwilkerson) Consider merging duplicate errors (same code,
    // location, and messages). If we do that, we should return the logical-or
    // of the hasFix fields from the merged errors.
    var count = partialResultList.length;
    if (count == 0) {
      return <AnalysisError>[];
    } else if (count == 1) {
      return partialResultList[0];
    }
    var mergedErrors = <AnalysisError>[];
    for (var partialResults in partialResultList) {
      mergedErrors.addAll(partialResults);
    }
    return mergedErrors;
  }

  /// Return a list of suggestions composed by merging the lists of suggestions
  /// in the [partialResultList].
  ///
  /// The resulting list will contain all of the suggestions from all of the
  /// plugins. If two or more plugins contribute the same suggestion the
  /// resulting list will contain duplications.
  List<CompletionSuggestion> mergeCompletionSuggestions(
      List<List<CompletionSuggestion>> partialResultList) {
    var count = partialResultList.length;
    if (count == 0) {
      return <CompletionSuggestion>[];
    } else if (count == 1) {
      return partialResultList[0];
    }
    var mergedSuggestions = <CompletionSuggestion>[];
    for (var partialResults in partialResultList) {
      mergedSuggestions.addAll(partialResults);
    }
    return mergedSuggestions;
  }

  /// Return a list of regions composed by merging the lists of regions in the
  /// [partialResultList].
  ///
  /// The resulting list will contain all of the folding regions from all of the
  /// plugins. If a plugin contributes a folding region that overlaps a region
  /// from a previous plugin, the overlapping region will be omitted. (For these
  /// purposes, if either region is fully contained within the other they are
  /// not considered to be overlapping.)
  List<FoldingRegion> mergeFoldingRegions(
      List<List<FoldingRegion>> partialResultList) {
    var count = partialResultList.length;
    if (count == 0) {
      return <FoldingRegion>[];
    } else if (count == 1) {
      return partialResultList[0];
    }
    var mergedRegions = partialResultList[0].toList();

    /// Return `true` if the [newRegion] does not overlap any of the regions in
    /// the collection of [mergedRegions].
    bool isNonOverlapping(FoldingRegion newRegion) {
      var newStart = newRegion.offset;
      var newEnd = newStart + newRegion.length;
      for (var existingRegion in mergedRegions) {
        var existingStart = existingRegion.offset;
        var existingEnd = existingStart + existingRegion.length;
        if (overlaps(newStart, newEnd, existingStart, existingEnd,
            allowNesting: true)) {
          return false;
        }
      }
      return true;
    }

    for (var i = 1; i < count; i++) {
      var partialResults = partialResultList[i];
      for (var region in partialResults) {
        if (isNonOverlapping(region)) {
          mergedRegions.add(region);
        }
      }
    }
    return mergedRegions;
  }

  /// Return a list of regions composed by merging the lists of regions in the
  /// [partialResultList].
  ///
  /// The resulting list will contain all of the highlight regions from all of
  /// the plugins. If two or more plugins contribute the same highlight region
  /// the resulting list will contain duplications.
  List<HighlightRegion> mergeHighlightRegions(
      List<List<HighlightRegion>> partialResultList) {
    var count = partialResultList.length;
    if (count == 0) {
      return <HighlightRegion>[];
    } else if (count == 1) {
      return partialResultList[0];
    }
    var mergedRegions = <HighlightRegion>[];
    for (var partialResults in partialResultList) {
      mergedRegions.addAll(partialResults);
    }
    return mergedRegions;
  }

  /// Return kythe entry result parameters composed by merging the parameters in
  /// the [partialResultList].
  ///
  /// The resulting list will contain all of the kythe entries from all of the
  /// plugins. If a plugin contributes a kythe entry that is the same as the
  /// entry from a different plugin, the entry will appear twice in the list.
  KytheGetKytheEntriesResult mergeKytheEntries(
      List<KytheGetKytheEntriesResult> partialResultList) {
    var mergedEntries = <KytheEntry>[];
    var mergedFiles = <String>{};
    for (var partialResult in partialResultList) {
      mergedEntries.addAll(partialResult.entries);
      mergedFiles.addAll(partialResult.files);
    }
    return KytheGetKytheEntriesResult(mergedEntries, mergedFiles.toList());
  }

  /// Return navigation notification parameters composed by merging the
  /// parameters in the [partialResultList].
  ///
  /// The resulting list will contain all of the navigation regions from all of
  /// the plugins. If a plugin contributes a navigation region that overlaps a
  /// region from a previous plugin, the overlapping region will be omitted.
  /// (For these purposes, nested regions are considered to be overlapping.)
  AnalysisNavigationParams mergeNavigation(
      List<AnalysisNavigationParams> partialResultList) {
    var count = partialResultList.length;
    if (count == 0) {
      return null;
    } else if (count == 1) {
      return partialResultList[0];
    }
    var base = partialResultList[0];
    var file = base.file;
    var mergedRegions = base.regions.toList();
    var mergedTargets = base.targets.toList();
    var mergedFiles = base.files.toList();

    /// Return `true` if the [newRegion] does not overlap any of the regions in
    /// the collection of [mergedRegions].
    bool isNonOverlapping(NavigationRegion newRegion) {
      var newStart = newRegion.offset;
      var newEnd = newStart + newRegion.length;
      for (var mergedRegion in mergedRegions) {
        var mergedStart = mergedRegion.offset;
        var mergedEnd = mergedStart + mergedRegion.length;
        if (overlaps(newStart, newEnd, mergedStart, mergedEnd)) {
          return false;
        }
      }
      return true;
    }

    /// Return the index of the region in the collection of [mergedRegions] that
    /// covers exactly the same region as the [newRegion], or `-1` if there is
    /// no such region.
    int matchingRegion(newRegion) {
      int newOffset = newRegion.offset;
      int newLength = newRegion.length;
      for (var i = 0; i < mergedRegions.length; i++) {
        var mergedRegion = mergedRegions[i];
        if (newOffset == mergedRegion.offset &&
            newLength == mergedRegion.length) {
          return i;
        }
      }
      return -1;
    }

    for (var i = 1; i < count; i++) {
      // For now we take the optimistic approach of assuming that most or all of
      // the regions will not overlap and that we therefore don't need to remove
      // any unreferenced files or targets from the lists. If that isn't true
      // then this could result in server sending more data to the client than
      // is necessary.
      var result = partialResultList[i];
      var regions = result.regions;
      var targets = result.targets;
      var files = result.files;
      //
      // Merge the file data.
      //
      var fileMap = <int, int>{};
      for (var j = 0; j < files.length; j++) {
        var file = files[j];
        var index = mergedFiles.indexOf(file);
        if (index < 0) {
          index = mergedFiles.length;
          mergedFiles.add(file);
        }
        fileMap[j] = index;
      }
      //
      // Merge the target data.
      //
      var targetMap = <int, int>{};
      for (var j = 0; j < targets.length; j++) {
        var target = targets[j];
        var newIndex = fileMap[target.fileIndex];
        if (target.fileIndex != newIndex) {
          target = NavigationTarget(target.kind, newIndex, target.offset,
              target.length, target.startLine, target.startColumn,
              codeOffset: target.codeOffset, codeLength: target.codeLength);
        }
        var index = mergedTargets.indexOf(target);
        if (index < 0) {
          index = mergedTargets.length;
          mergedTargets.add(target);
        }
        targetMap[j] = index;
      }
      //
      // Merge the region data.
      //
      for (var j = 0; j < regions.length; j++) {
        var region = regions[j];
        var newTargets = region.targets
            .map((int oldTarget) => targetMap[oldTarget])
            .toList();
        if (region.targets != newTargets) {
          region = NavigationRegion(region.offset, region.length, newTargets);
        }
        var index = matchingRegion(region);
        if (index >= 0) {
          var mergedRegion = mergedRegions[index];
          var mergedTargets = mergedRegion.targets;
          var added = false;
          for (var target in region.targets) {
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
                mergedRegion = NavigationRegion(
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
    return AnalysisNavigationParams(
        file, mergedRegions, mergedTargets, mergedFiles);
  }

  /// Return a list of occurrences composed by merging the lists of occurrences
  /// in the [partialResultList].
  ///
  /// The resulting list of occurrences will contain exactly one occurrences for
  /// every element for which there is at least one occurrences. If two or more
  /// plugins contribute an occurrences for the same element, the resulting
  /// occurrences for that element will include all of the locations from all of
  /// the plugins without duplications.
  List<Occurrences> mergeOccurrences(
      List<List<Occurrences>> partialResultList) {
    var count = partialResultList.length;
    if (count == 0) {
      return <Occurrences>[];
    } else if (count == 1) {
      return partialResultList[0];
    }
    var elementMap = <Element, Set<int>>{};
    for (var partialResults in partialResultList) {
      for (var occurances in partialResults) {
        var element = occurances.element;
        var offsets = elementMap.putIfAbsent(element, () => HashSet<int>());
        offsets.addAll(occurances.offsets);
      }
    }
    var mergedOccurrences = <Occurrences>[];
    elementMap.forEach((Element element, Set<int> offsets) {
      var sortedOffsets = offsets.toList();
      sortedOffsets.sort();
      mergedOccurrences
          .add(Occurrences(element, sortedOffsets, element.name.length));
    });
    return mergedOccurrences;
  }

  /// Return a list of outlines composed by merging the lists of outlines in the
  /// [partialResultList].
  ///
  /// The resulting list of outlines will contain ...
  ///
  /// Throw an exception if any of the outlines are associated with an element
  /// that does not have a location.
  ///
  /// Throw an exception if any outline has children that are also children of
  /// another outline. No exception is thrown if a plugin contributes a
  /// top-level outline that is a child of an outline contributed by a different
  /// plugin.
  List<Outline> mergeOutline(List<List<Outline>> partialResultList) {
    /// Return a key encoding the unique attributes of the given [element].
    String computeKey(Element element) {
      var location = element.location;
      if (location == null) {
        throw StateError(
            'Elements in an outline are expected to have a location');
      }
      var buffer = StringBuffer();
      buffer.write(location.offset);
      buffer.write(';');
      buffer.write(element.kind.name);
      return buffer.toString();
    }

    var count = partialResultList.length;
    if (count == 0) {
      return <Outline>[];
    } else if (count == 1) {
      return partialResultList[0];
    }
    var mergedOutlines = partialResultList[0].toList();
    var outlineMap = <String, Outline>{};
    var copyMap = <Outline, Outline>{};

    /// Add the given [outline] and all of its children to the [outlineMap].
    void addToMap(Outline outline) {
      var key = computeKey(outline.element);
      if (outlineMap.containsKey(key)) {
        // TODO(brianwilkerson) Decide how to handle this more gracefully.
        throw StateError('Inconsistent outlines');
      }
      outlineMap[key] = outline;
      outline.children?.forEach(addToMap);
    }

    /// Merge the children of the [newOutline] into the list of children of the
    /// [mergedOutline].
    void mergeChildren(Outline mergedOutline, Outline newOutline) {
      for (var newChild in newOutline.children) {
        var mergedChild = outlineMap[computeKey(newChild.element)];
        if (mergedChild == null) {
          // The [newChild] isn't in the existing list.
          var copiedOutline = copyMap.putIfAbsent(
              mergedOutline,
              () => Outline(
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
    for (var i = 1; i < count; i++) {
      for (var outline in partialResultList[i]) {
        var mergedOutline = outlineMap[computeKey(outline.element)];
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

    /// Perform a depth first traversal of the outline structure rooted at the
    /// given [outline] item, re-building each item if any of its children have
    /// been updated by the merge process.
    Outline traverse(Outline outline) {
      var copiedOutline = copyMap[outline];
      var isCopied = copiedOutline != null;
      copiedOutline ??= outline;
      var currentChildren = copiedOutline.children;
      if (currentChildren == null || currentChildren.isEmpty) {
        return outline;
      }
      var updatedChildren =
          currentChildren.map((Outline child) => traverse(child)).toList();
      if (currentChildren != updatedChildren) {
        if (!isCopied) {
          return Outline(
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

    for (var i = 0; i < mergedOutlines.length; i++) {
      mergedOutlines[i] = traverse(mergedOutlines[i]);
    }
    return mergedOutlines;
  }

  /// Return a list of source changes composed by merging the lists of source
  /// changes in the [partialResultList].
  ///
  /// The resulting list will contain all of the source changes from all of the
  /// plugins. If two or more plugins contribute the same source change the
  /// resulting list will contain duplications.
  List<plugin.PrioritizedSourceChange> mergePrioritizedSourceChanges(
      List<List<plugin.PrioritizedSourceChange>> partialResultList) {
    var count = partialResultList.length;
    if (count == 0) {
      return <plugin.PrioritizedSourceChange>[];
    } else if (count == 1) {
      return partialResultList[0];
    }
    var mergedChanges = <plugin.PrioritizedSourceChange>[];
    for (var partialResults in partialResultList) {
      mergedChanges.addAll(partialResults);
    }
    mergedChanges.sort((first, second) => first.priority - second.priority);
    return mergedChanges;
  }

  /// Return a refactoring feedback composed by merging the refactoring
  /// feedbacks in the [partialResultList].
  ///
  /// The content of the resulting feedback depends on the kind of feedbacks
  /// being merged.
  ///
  /// Throw an exception if the refactoring feedbacks are of an unhandled type.
  ///
  /// The feedbacks in the [partialResultList] are expected to all be of the
  /// same type. If that expectation is violated, and exception might be thrown.
  RefactoringFeedback mergeRefactoringFeedbacks(
      List<RefactoringFeedback> feedbacks) {
    var count = feedbacks.length;
    if (count == 0) {
      return null;
    } else if (count == 1) {
      return feedbacks[0];
    }
    var first = feedbacks[0];
    if (first is ConvertGetterToMethodFeedback) {
      // The feedbacks are empty, so there's nothing to merge.
      return first;
    } else if (first is ConvertMethodToGetterFeedback) {
      // The feedbacks are empty, so there's nothing to merge.
      return first;
    } else if (first is ExtractLocalVariableFeedback) {
      var coveringExpressionOffsets = first.coveringExpressionOffsets == null
          ? <int>[]
          : first.coveringExpressionOffsets.toList();
      var coveringExpressionLengths = first.coveringExpressionLengths == null
          ? <int>[]
          : first.coveringExpressionLengths.toList();
      var names = first.names.toList();
      var offsets = first.offsets.toList();
      var lengths = first.lengths.toList();
      for (var i = 1; i < count; i++) {
        ExtractLocalVariableFeedback feedback = feedbacks[i];
        // TODO(brianwilkerson) This doesn't ensure that the covering data is in
        // the right order and consistent.
        if (feedback.coveringExpressionOffsets != null) {
          coveringExpressionOffsets.addAll(feedback.coveringExpressionOffsets);
        }
        if (feedback.coveringExpressionLengths != null) {
          coveringExpressionLengths.addAll(feedback.coveringExpressionLengths);
        }
        for (var name in feedback.names) {
          if (!names.contains(name)) {
            names.add(name);
          }
        }
        offsets.addAll(feedback.offsets);
        lengths.addAll(feedback.lengths);
      }
      return ExtractLocalVariableFeedback(names.toList(), offsets, lengths,
          coveringExpressionOffsets: (coveringExpressionOffsets.isEmpty
              ? null
              : coveringExpressionOffsets),
          coveringExpressionLengths: (coveringExpressionLengths.isEmpty
              ? null
              : coveringExpressionLengths));
    } else if (first is ExtractMethodFeedback) {
      var offset = first.offset;
      var length = first.length;
      var returnType = first.returnType;
      var names = first.names.toList();
      var canCreateGetter = first.canCreateGetter;
      var parameters = first.parameters;
      var offsets = first.offsets.toList();
      var lengths = first.lengths.toList();
      for (var i = 1; i < count; i++) {
        ExtractMethodFeedback feedback = feedbacks[i];
        if (returnType.isEmpty) {
          returnType = feedback.returnType;
        }
        for (var name in feedback.names) {
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
      return ExtractMethodFeedback(offset, length, returnType, names.toList(),
          canCreateGetter, parameters, offsets, lengths);
    } else if (first is InlineLocalVariableFeedback) {
      var occurrences = first.occurrences;
      for (var i = 1; i < count; i++) {
        occurrences +=
            (feedbacks[i] as InlineLocalVariableFeedback).occurrences;
      }
      return InlineLocalVariableFeedback(first.name, occurrences);
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
    throw StateError(
        'Unsupported class of refactoring feedback: ${first.runtimeType}');
  }

  /// Return a list of refactoring kinds composed by merging the lists of
  /// refactoring kinds in the [partialResultList].
  ///
  /// The resulting list will contain all of the refactoring kinds from all of
  /// the plugins, but will not contain duplicate elements.
  List<RefactoringKind> mergeRefactoringKinds(
      List<List<RefactoringKind>> partialResultList) {
    var count = partialResultList.length;
    if (count == 0) {
      return <RefactoringKind>[];
    } else if (count == 1) {
      return partialResultList[0];
    }
    Set<RefactoringKind> mergedKinds = HashSet<RefactoringKind>();
    for (var partialResults in partialResultList) {
      mergedKinds.addAll(partialResults);
    }
    return mergedKinds.toList();
  }

  /// Return the result for a getRefactorings request composed by merging the
  /// results in the [partialResultList].
  ///
  /// The returned result will contain the concatenation of the initial,
  /// options, and final problems. If two or more plugins produce the same
  /// problem, then the resulting list of problems will contain duplications.
  ///
  /// The returned result will contain a merged list of refactoring feedbacks
  /// (as defined by [mergeRefactoringFeedbacks]) and a merged list of source
  /// changes (as defined by [mergeChanges]).
  ///
  /// The returned result will contain the concatenation of the potential edits.
  /// If two or more plugins produce the same potential edit, then the resulting
  /// list of potential edits will contain duplications.
  EditGetRefactoringResult mergeRefactorings(
      List<EditGetRefactoringResult> partialResultList) {
    /// Return the result of merging the given list of source [changes] into a
    /// single source change.
    ///
    /// The resulting change will have the first non-null message and the first
    /// non-null selection. The linked edit groups will be a concatenation of
    /// all of the individual linked edit groups because there's no way to
    /// determine when two such groups should be merged. The resulting list of
    /// edits will be merged at the level of the file being edited, but will be
    /// a concatenation of the individual edits within each file, even if
    /// multiple plugins contribute duplicate or conflicting edits.
    SourceChange mergeChanges(List<SourceChange> changes) {
      var count = changes.length;
      if (count == 0) {
        return null;
      } else if (count == 1) {
        return changes[0];
      }
      var first = changes[0];
      var message = first.message;
      var editMap = <String, SourceFileEdit>{};
      for (var edit in first.edits) {
        editMap[edit.file] = edit;
      }
      var linkedEditGroups = first.linkedEditGroups.toList();
      var selection = first.selection;
      for (var i = 1; i < count; i++) {
        var change = changes[i];
        for (var edit in change.edits) {
          var mergedEdit = editMap[edit.file];
          if (mergedEdit == null) {
            editMap[edit.file] = edit;
          } else {
            // This doesn't detect if multiple plugins contribute the same (or
            // conflicting) edits.
            var edits = mergedEdit.edits.toList();
            edits.addAll(edit.edits);
            editMap[edit.file] = SourceFileEdit(
                mergedEdit.file, mergedEdit.fileStamp,
                edits: edits);
          }
        }
        linkedEditGroups.addAll(change.linkedEditGroups);
        message ??= change.message;
        selection ??= change.selection;
      }
      return SourceChange(message,
          edits: editMap.values.toList(),
          linkedEditGroups: linkedEditGroups,
          selection: selection);
    }

    var count = partialResultList.length;
    if (count == 0) {
      return null;
    } else if (count == 1) {
      return partialResultList[0];
    }
    var result = partialResultList[0];
    var initialProblems = result.initialProblems.toList();
    var optionsProblems = result.optionsProblems.toList();
    var finalProblems = result.finalProblems.toList();
    var feedbacks = <RefactoringFeedback>[];
    if (result.feedback != null) {
      feedbacks.add(result.feedback);
    }
    var changes = <SourceChange>[];
    if (result.change != null) {
      changes.add(result.change);
    }
    var potentialEdits = result.potentialEdits.toList();
    for (var i = 1; i < count; i++) {
      var result = partialResultList[1];
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
    return EditGetRefactoringResult(
        initialProblems, optionsProblems, finalProblems,
        feedback: mergeRefactoringFeedbacks(feedbacks),
        change: mergeChanges(changes),
        potentialEdits: potentialEdits);
  }

  /// Return a list of source changes composed by merging the lists of source
  /// changes in the [partialResultList].
  ///
  /// The resulting list will contain all of the source changes from all of the
  /// plugins. If two or more plugins contribute the same source change the
  /// resulting list will contain duplications.
  List<SourceChange> mergeSourceChanges(
      List<List<SourceChange>> partialResultList) {
    var count = partialResultList.length;
    if (count == 0) {
      return <SourceChange>[];
    } else if (count == 1) {
      return partialResultList[0];
    }
    var mergedChanges = <SourceChange>[];
    for (var partialResults in partialResultList) {
      mergedChanges.addAll(partialResults);
    }
    return mergedChanges;
  }

  /// Return `true` if a region extending from [leftStart] (inclusive) to
  /// [leftEnd] (exclusive) overlaps a region extending from [rightStart]
  /// (inclusive) to [rightEnd] (exclusive). If [allowNesting] is `true`, then
  /// the regions are allowed to overlap as long as one region is completely
  /// nested within the other region.
  @visibleForTesting
  bool overlaps(int leftStart, int leftEnd, int rightStart, int rightEnd,
      {bool allowNesting = false}) {
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
