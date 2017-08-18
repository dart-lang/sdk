import 'dart:io' as io;
import 'dart:math' show min;

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/cache.dart';
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart' show TypeProvider;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/resynthesize.dart';
import 'package:analyzer/src/task/dart.dart';
import 'package:analyzer/task/dart.dart';
import 'package:analyzer/task/general.dart';
import 'package:analyzer/task/model.dart';
import 'package:front_end/src/base/source.dart';

/**
 * A [ConflictingSummaryException] indicates that two different summaries
 * provided to a [SummaryDataStore] conflict.
 */
class ConflictingSummaryException implements Exception {
  final String duplicatedUri;
  final String summary1Uri;
  final String summary2Uri;
  String _message;

  ConflictingSummaryException(Iterable<String> summaryPaths, this.duplicatedUri,
      this.summary1Uri, this.summary2Uri) {
    // Paths are often quite long.  Find and extract out a common prefix to
    // build a more readable error message.
    var prefix = _commonPrefix(summaryPaths.toList());
    _message = '''
These summaries conflict because they overlap:
- ${summary1Uri.substring(prefix)}
- ${summary2Uri.substring(prefix)}
Both contain the file: $duplicatedUri.
This typically indicates an invalid build rule where two or more targets
include the same source.
  ''';
  }

  String toString() => _message;

  /// Given a set of file paths, find a common prefix.
  int _commonPrefix(List<String> strings) {
    if (strings.isEmpty) return 0;
    var first = strings.first;
    int common = first.length;
    for (int i = 1; i < strings.length; ++i) {
      var current = strings[i];
      common = min(common, current.length);
      for (int j = 0; j < common; ++j) {
        if (first[j] != current[j]) {
          common = j;
          if (common == 0) return 0;
          break;
        }
      }
    }
    // The prefix should end with a file separator.
    var last =
        first.substring(0, common).lastIndexOf(io.Platform.pathSeparator);
    return last < 0 ? 0 : last + 1;
  }
}

/**
 * The [ResultProvider] that provides results from input package summaries.
 */
class InputPackagesResultProvider extends ResynthesizerResultProvider {
  InputPackagesResultProvider(
      InternalAnalysisContext context, SummaryDataStore dataStore)
      : super(context, dataStore) {
    createResynthesizer();
    context.typeProvider = resynthesizer.typeProvider;
    resynthesizer.finishCoreAsyncLibraries();
  }

  @override
  bool hasResultsForSource(Source source) {
    String uriString = source.uri.toString();
    return resynthesizer.hasLibrarySummary(uriString);
  }
}

/**
 * The [UriResolver] that knows about sources that are served from their
 * summaries.
 */
@deprecated
class InSummaryPackageUriResolver extends UriResolver {
  final SummaryDataStore _dataStore;

  InSummaryPackageUriResolver(this._dataStore);

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) {
    actualUri ??= uri;
    String uriString = uri.toString();
    UnlinkedUnit unit = _dataStore.unlinkedMap[uriString];
    if (unit != null) {
      String summaryPath = _dataStore.uriToSummaryPath[uriString];
      return new InSummarySource(actualUri, summaryPath);
    }
    return null;
  }
}

/**
 * A placeholder of a source that is part of a package whose analysis results
 * are served from its summary.  This source uses its URI as [fullName] and has
 * empty contents.
 */
class InSummarySource extends BasicSource {
  /**
   * The summary file where this source was defined.
   */
  final String summaryPath;

  InSummarySource(Uri uri, this.summaryPath) : super(uri);

  @override
  TimestampedData<String> get contents => new TimestampedData<String>(0, '');

  @override
  int get modificationStamp => 0;

  @override
  UriKind get uriKind => UriKind.PACKAGE_URI;

  @override
  bool exists() => true;

  @override
  String toString() => uri.toString();
}

/**
 * The [UriResolver] that knows about sources that are served from their
 * summaries.
 */
class InSummaryUriResolver extends UriResolver {
  ResourceProvider resourceProvider;
  final SummaryDataStore _dataStore;

  InSummaryUriResolver(this.resourceProvider, this._dataStore);

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) {
    actualUri ??= uri;
    String uriString = uri.toString();
    UnlinkedUnit unit = _dataStore.unlinkedMap[uriString];
    if (unit != null) {
      String summaryPath = _dataStore.uriToSummaryPath[uriString];
      return new InSummarySource(actualUri, summaryPath);
    }
    return null;
  }
}

/**
 * The [ResultProvider] that provides results using summary resynthesizer.
 */
abstract class ResynthesizerResultProvider extends ResultProvider {
  final InternalAnalysisContext context;
  final SummaryDataStore _dataStore;

  StoreBasedSummaryResynthesizer _resynthesizer;

  ResynthesizerResultProvider(this.context, this._dataStore);

  SummaryResynthesizer get resynthesizer => _resynthesizer;

  /**
   * Add a new [bundle] to the resynthesizer.
   */
  void addBundle(String path, PackageBundle bundle) {
    _dataStore.addBundle(path, bundle);
  }

  @override
  bool compute(CacheEntry entry, ResultDescriptor result) {
    AnalysisTarget target = entry.target;

    if (result == TYPE_PROVIDER) {
      entry.setValue(result as ResultDescriptor<TypeProvider>,
          _resynthesizer.typeProvider, TargetedResult.EMPTY_LIST);
      return true;
    }

    // LINE_INFO can be provided using just the UnlinkedUnit.
    if (target is Source && result == LINE_INFO) {
      String uriString = target.uri.toString();
      UnlinkedUnit unlinkedUnit = _dataStore.unlinkedMap[uriString];
      if (unlinkedUnit != null) {
        List<int> lineStarts = unlinkedUnit.lineStarts;
        if (lineStarts.isNotEmpty) {
          LineInfo lineInfo = new LineInfo(lineStarts);
          entry.setValue(result as ResultDescriptor<LineInfo>, lineInfo,
              TargetedResult.EMPTY_LIST);
          return true;
        }
      }
      return false;
    }

    // Check whether there are results for the source.
    if (!hasResultsForSource(target.librarySource ?? target.source)) {
      return false;
    }
    // Constant expressions are always resolved in summaries.
    if (result == CONSTANT_EXPRESSION_RESOLVED &&
        target is ConstantEvaluationTarget) {
      entry.setValue(
          result as ResultDescriptor<bool>, true, TargetedResult.EMPTY_LIST);
      return true;
    }
    // Provide results for Source.
    if (target is Source) {
      String uriString = target.uri.toString();
      // Provide known results.
      if (result == LIBRARY_ELEMENT1 ||
          result == LIBRARY_ELEMENT2 ||
          result == LIBRARY_ELEMENT3 ||
          result == LIBRARY_ELEMENT4 ||
          result == LIBRARY_ELEMENT5 ||
          result == LIBRARY_ELEMENT6 ||
          result == LIBRARY_ELEMENT7 ||
          result == LIBRARY_ELEMENT8 ||
          result == LIBRARY_ELEMENT9 ||
          result == LIBRARY_ELEMENT) {
        LibraryElement libraryElement =
            resynthesizer.getLibraryElement(uriString);
        entry.setValue(result as ResultDescriptor<LibraryElement>,
            libraryElement, TargetedResult.EMPTY_LIST);
        return true;
      } else if (result == READY_LIBRARY_ELEMENT2 ||
          result == READY_LIBRARY_ELEMENT6 ||
          result == READY_LIBRARY_ELEMENT7) {
        entry.setValue(
            result as ResultDescriptor<bool>, true, TargetedResult.EMPTY_LIST);
        return true;
      } else if (result == MODIFICATION_TIME) {
        entry.setValue(
            result as ResultDescriptor<int>, 0, TargetedResult.EMPTY_LIST);
        return true;
      } else if (result == SOURCE_KIND) {
        UnlinkedUnit unlinked = _dataStore.unlinkedMap[uriString];
        if (unlinked != null) {
          entry.setValue(
              result as ResultDescriptor<SourceKind>,
              unlinked.isPartOf ? SourceKind.PART : SourceKind.LIBRARY,
              TargetedResult.EMPTY_LIST);
          return true;
        }
        return false;
      } else if (result == CONTAINING_LIBRARIES) {
        List<String> libraryUriStrings =
            _dataStore.getContainingLibraryUris(uriString);
        if (libraryUriStrings != null) {
          List<Source> librarySources = libraryUriStrings
              .map((libraryUriString) =>
                  context.sourceFactory.resolveUri(target, libraryUriString))
              .toList(growable: false);
          entry.setValue(result as ResultDescriptor<List<Source>>,
              librarySources, TargetedResult.EMPTY_LIST);
          return true;
        }
        return false;
      }
    } else if (target is LibrarySpecificUnit) {
      if (result == CREATED_RESOLVED_UNIT1 ||
          result == CREATED_RESOLVED_UNIT2 ||
          result == CREATED_RESOLVED_UNIT3 ||
          result == CREATED_RESOLVED_UNIT4 ||
          result == CREATED_RESOLVED_UNIT5 ||
          result == CREATED_RESOLVED_UNIT6 ||
          result == CREATED_RESOLVED_UNIT7 ||
          result == CREATED_RESOLVED_UNIT8 ||
          result == CREATED_RESOLVED_UNIT9 ||
          result == CREATED_RESOLVED_UNIT10 ||
          result == CREATED_RESOLVED_UNIT11) {
        entry.setValue(
            result as ResultDescriptor<bool>, true, TargetedResult.EMPTY_LIST);
        return true;
      }
      if (result == COMPILATION_UNIT_ELEMENT) {
        String libraryUri = target.library.uri.toString();
        String unitUri = target.unit.uri.toString();
        CompilationUnitElement unit = resynthesizer.getElement(
            new ElementLocationImpl.con3(<String>[libraryUri, unitUri]));
        if (unit != null) {
          entry.setValue(result as ResultDescriptor<CompilationUnitElement>,
              unit, TargetedResult.EMPTY_LIST);
          return true;
        }
      }
    } else if (target is VariableElement) {
      if (result == INFERRED_STATIC_VARIABLE) {
        entry.setValue(result as ResultDescriptor<VariableElement>, target,
            TargetedResult.EMPTY_LIST);
        return true;
      }
    }
    // Unknown target.
    return false;
  }

  /**
   * Create the [resynthesizer] instance.
   *
   * Subclasses must call this method in their constructors.
   */
  void createResynthesizer() {
    _resynthesizer = new StoreBasedSummaryResynthesizer(context,
        context.sourceFactory, context.analysisOptions.strongMode, _dataStore);
  }

  /**
   * Return `true` if this result provider can provide a result for the
   * given [source].  The provider must ensure that [addBundle] is invoked for
   * every bundle that would be required to provide results for the [source].
   */
  bool hasResultsForSource(Source source);
}

/**
 * A concrete resynthesizer that serves summaries from [SummaryDataStore].
 */
class StoreBasedSummaryResynthesizer extends SummaryResynthesizer {
  final SummaryDataStore _dataStore;

  StoreBasedSummaryResynthesizer(AnalysisContext context,
      SourceFactory sourceFactory, bool strongMode, this._dataStore)
      : super(context, sourceFactory, strongMode);

  @override
  LinkedLibrary getLinkedSummary(String uri) {
    return _dataStore.linkedMap[uri];
  }

  @override
  UnlinkedUnit getUnlinkedSummary(String uri) {
    return _dataStore.unlinkedMap[uri];
  }

  @override
  bool hasLibrarySummary(String uri) {
    LinkedLibrary linkedLibrary = _dataStore.linkedMap[uri];
    return linkedLibrary != null;
  }
}

/**
 * A [SummaryDataStore] is a container for the data extracted from a set of
 * summary package bundles.  It contains maps which can be used to find linked
 * and unlinked summaries by URI.
 */
class SummaryDataStore {
  /**
   * List of all [PackageBundle]s.
   */
  final List<PackageBundle> bundles = <PackageBundle>[];

  /**
   * Map from the URI of a compilation unit to the unlinked summary of that
   * compilation unit.
   */
  final Map<String, UnlinkedUnit> unlinkedMap = <String, UnlinkedUnit>{};

  /**
   * Map from the URI of a library to the linked summary of that library.
   */
  final Map<String, LinkedLibrary> linkedMap = <String, LinkedLibrary>{};

  /**
   * Map from the URI of a library to the summary path that contained it.
   */
  final Map<String, String> uriToSummaryPath = <String, String>{};

  /**
   * List of summary paths.
   */
  final Iterable<String> _summaryPaths;

  /**
   * If true, do not accept multiple summaries that contain the same Dart uri.
   */
  bool _disallowOverlappingSummaries;

  /**
   * Create a [SummaryDataStore] and populate it with the summaries in
   * [summaryPaths].
   */
  SummaryDataStore(Iterable<String> summaryPaths,
      {bool disallowOverlappingSummaries: false,
      ResourceProvider resourceProvider})
      : _summaryPaths = summaryPaths,
        _disallowOverlappingSummaries = disallowOverlappingSummaries {
    summaryPaths.forEach((String path) => _fillMaps(path, resourceProvider));
  }

  /**
   * Add the given [bundle] loaded from the file with the given [path].
   */
  void addBundle(String path, PackageBundle bundle) {
    bundles.add(bundle);
    for (int i = 0; i < bundle.unlinkedUnitUris.length; i++) {
      String uri = bundle.unlinkedUnitUris[i];
      if (_disallowOverlappingSummaries &&
          uriToSummaryPath.containsKey(uri) &&
          (uriToSummaryPath[uri] != path)) {
        throw new ConflictingSummaryException(
            _summaryPaths, uri, uriToSummaryPath[uri], path);
      }
      uriToSummaryPath[uri] = path;
      addUnlinkedUnit(uri, bundle.unlinkedUnits[i]);
    }
    for (int i = 0; i < bundle.linkedLibraryUris.length; i++) {
      String uri = bundle.linkedLibraryUris[i];
      addLinkedLibrary(uri, bundle.linkedLibraries[i]);
    }
  }

  /**
   * Add the given [linkedLibrary] with the given [uri].
   */
  void addLinkedLibrary(String uri, LinkedLibrary linkedLibrary) {
    linkedMap[uri] = linkedLibrary;
  }

  /**
   * Add into this store the unlinked units and linked libraries of [other].
   */
  void addStore(SummaryDataStore other) {
    unlinkedMap.addAll(other.unlinkedMap);
    linkedMap.addAll(other.linkedMap);
  }

  /**
   * Add the given [unlinkedUnit] with the given [uri].
   */
  void addUnlinkedUnit(String uri, UnlinkedUnit unlinkedUnit) {
    unlinkedMap[uri] = unlinkedUnit;
  }

  /**
   * Return a list of absolute URIs of the libraries that contain the unit with
   * the given [unitUriString], or `null` if no such library is in the store.
   */
  List<String> getContainingLibraryUris(String unitUriString) {
    // The unit is the defining unit of a library.
    if (linkedMap.containsKey(unitUriString)) {
      return <String>[unitUriString];
    }
    // Check every unlinked unit whether it uses [unitUri] as a part.
    List<String> libraryUriStrings = <String>[];
    unlinkedMap.forEach((unlinkedUnitUriString, unlinkedUnit) {
      Uri libraryUri = Uri.parse(unlinkedUnitUriString);
      for (String partUriString in unlinkedUnit.publicNamespace.parts) {
        Uri partUri = Uri.parse(partUriString);
        String partAbsoluteUriString =
            resolveRelativeUri(libraryUri, partUri).toString();
        if (partAbsoluteUriString == unitUriString) {
          libraryUriStrings.add(unlinkedUnitUriString);
        }
      }
    });
    return libraryUriStrings.isNotEmpty ? libraryUriStrings : null;
  }

  /**
   * Return `true` if the store contains the unlinked summary for the unit
   * with the given absolute [uri].
   */
  bool hasUnlinkedUnit(String uri) {
    return unlinkedMap.containsKey(uri);
  }

  void _fillMaps(String path, ResourceProvider resourceProvider) {
    List<int> buffer;
    if (resourceProvider != null) {
      var file = resourceProvider.getFile(path);
      buffer = file.readAsBytesSync();
    } else {
      io.File file = new io.File(path);
      buffer = file.readAsBytesSync();
    }
    PackageBundle bundle = new PackageBundle.fromBuffer(buffer);
    addBundle(path, bundle);
  }
}
