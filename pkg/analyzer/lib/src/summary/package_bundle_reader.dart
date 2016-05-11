import 'dart:io' as io;

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/context/cache.dart';
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/resynthesize.dart';
import 'package:analyzer/src/summary/summary_sdk.dart';
import 'package:analyzer/src/task/dart.dart';
import 'package:analyzer/task/dart.dart';
import 'package:analyzer/task/model.dart';
import 'package:path/path.dart' as pathos;

/**
 * The [ResultProvider] that provides results from input package summaries.
 */
class InputPackagesResultProvider extends ResultProvider {
  final InternalAnalysisContext _context;

  _FileBasedSummaryResynthesizer _resynthesizer;
  SummaryResultProvider _sdkProvider;

  InputPackagesResultProvider(this._context, SummaryDataStore dataStore) {
    InternalAnalysisContext sdkContext = _context.sourceFactory.dartSdk.context;
    _sdkProvider = sdkContext.resultProvider;
    // Set the type provider to prevent the context from computing it.
    _context.typeProvider = sdkContext.typeProvider;
    // Create a chained resynthesizer.
    _resynthesizer = new _FileBasedSummaryResynthesizer(
        _sdkProvider.resynthesizer,
        _context,
        _context.typeProvider,
        _context.sourceFactory,
        _context.analysisOptions.strongMode,
        dataStore);
  }

  @override
  bool compute(CacheEntry entry, ResultDescriptor result) {
    if (_sdkProvider.compute(entry, result)) {
      return true;
    }
    AnalysisTarget target = entry.target;
    // Only library results are supported for now.
    if (target is Source) {
      Uri uri = target.uri;
      // We know how to server results to input packages.
      String uriString = uri.toString();
      if (!_resynthesizer.hasLibrarySummary(uriString)) {
        return false;
      }
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
          result == LIBRARY_ELEMENT ||
          false) {
        LibraryElement libraryElement =
            _resynthesizer.getLibraryElement(uriString);
        entry.setValue(result, libraryElement, TargetedResult.EMPTY_LIST);
        return true;
      } else if (result == READY_LIBRARY_ELEMENT2 ||
          result == READY_LIBRARY_ELEMENT6 ||
          result == READY_LIBRARY_ELEMENT7) {
        entry.setValue(result, true, TargetedResult.EMPTY_LIST);
        return true;
      } else if (result == SOURCE_KIND) {
        if (_resynthesizer._dataStore.linkedMap.containsKey(uriString)) {
          entry.setValue(result, SourceKind.LIBRARY, TargetedResult.EMPTY_LIST);
          return true;
        }
        if (_resynthesizer._dataStore.unlinkedMap.containsKey(uriString)) {
          entry.setValue(result, SourceKind.PART, TargetedResult.EMPTY_LIST);
          return true;
        }
        return false;
      }
    } else if (target is LibrarySpecificUnit) {
      String uriString = target.library.uri.toString();
      if (!_resynthesizer.hasLibrarySummary(uriString)) {
        return false;
      }
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
          result == CREATED_RESOLVED_UNIT11 ||
          result == CREATED_RESOLVED_UNIT12) {
        entry.setValue(result, true, TargetedResult.EMPTY_LIST);
        return true;
      }
      if (result == COMPILATION_UNIT_ELEMENT) {
        String libraryUri = target.library.uri.toString();
        String unitUri = target.unit.uri.toString();
        CompilationUnitElement unit = _resynthesizer.getElement(
            new ElementLocationImpl.con3(<String>[libraryUri, unitUri]));
        if (unit != null) {
          entry.setValue(result, unit, TargetedResult.EMPTY_LIST);
          return true;
        }
      }
    } else if (target is VariableElement) {
      if (!_resynthesizer
          .hasLibrarySummary(target.library.source.uri.toString())) {
        return false;
      }
      if (result == PROPAGATED_VARIABLE || result == INFERRED_STATIC_VARIABLE) {
        entry.setValue(result, target, TargetedResult.EMPTY_LIST);
        return true;
      }
    }
    return false;
  }
}

/**
 * The [UriResolver] that knows about sources that are served from their
 * summaries.
 */
class InSummaryPackageUriResolver extends UriResolver {
  final SummaryDataStore _dataStore;

  InSummaryPackageUriResolver(this._dataStore);

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) {
    actualUri ??= uri;
    UnlinkedUnit unit = _dataStore.unlinkedMap[uri.toString()];
    if (unit != null) {
      String summaryPath = _dataStore.uriToSummaryPath[uri.toString()];
      if (unit.fallbackModePath.isNotEmpty) {
        return new _InSummaryFallbackSource(
            new JavaFile(unit.fallbackModePath), actualUri, summaryPath);
      } else {
        return new InSummarySource(actualUri, summaryPath);
      }
    }
    return null;
  }
}

/**
 * A placeholder of a source that is part of a package whose analysis results
 * are served from its summary.  This source uses its URI as [fullName] and has
 * empty contents.
 */
class InSummarySource extends Source {
  final Uri uri;

  /**
   * The summary file where this source was defined.
   */
  final String summaryPath;

  InSummarySource(this.uri, this.summaryPath);

  @override
  TimestampedData<String> get contents => new TimestampedData<String>(0, '');

  @override
  String get encoding => uri.toString();

  @override
  String get fullName => encoding;

  @override
  int get hashCode => uri.hashCode;

  @override
  bool get isInSystemLibrary => false;

  @override
  int get modificationStamp => 0;

  @override
  String get shortName => pathos.basename(fullName);

  @override
  UriKind get uriKind => UriKind.PACKAGE_URI;

  @override
  bool operator ==(Object object) =>
      object is InSummarySource && object.uri == uri;

  @override
  bool exists() => true;

  @override
  String toString() => uri.toString();
}

/**
 * A [SummaryDataStore] is a container for the data extracted from a set of
 * summary package bundles.  It contains maps which can be used to find linked
 * and unlinked summaries by URI.
 */
class SummaryDataStore {
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

  SummaryDataStore(Iterable<String> summaryPaths) {
    summaryPaths.forEach(_fillMaps);
  }

  /**
   * Add the given [bundle] loaded from the file with the given [path].
   */
  void addBundle(String path, PackageBundle bundle) {
    for (int i = 0; i < bundle.unlinkedUnitUris.length; i++) {
      String uri = bundle.unlinkedUnitUris[i];
      uriToSummaryPath[uri] = path;
      unlinkedMap[uri] = bundle.unlinkedUnits[i];
    }
    for (int i = 0; i < bundle.linkedLibraryUris.length; i++) {
      String uri = bundle.linkedLibraryUris[i];
      linkedMap[uri] = bundle.linkedLibraries[i];
    }
  }

  void _fillMaps(String path) {
    io.File file = new io.File(path);
    List<int> buffer = file.readAsBytesSync();
    PackageBundle bundle = new PackageBundle.fromBuffer(buffer);
    addBundle(path, bundle);
  }
}

/**
 * A concrete resynthesizer that serves summaries from given file paths.
 */
class _FileBasedSummaryResynthesizer extends SummaryResynthesizer {
  final SummaryDataStore _dataStore;

  _FileBasedSummaryResynthesizer(
      SummaryResynthesizer parent,
      AnalysisContext context,
      TypeProvider typeProvider,
      SourceFactory sourceFactory,
      bool strongMode,
      this._dataStore)
      : super(parent, context, typeProvider, sourceFactory, strongMode);

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
    return linkedLibrary != null && !linkedLibrary.fallbackMode;
  }
}

/**
 * A source that is part of a package whose summary was generated in fallback
 * mode.  This source behaves identically to a [FileBasedSource] except that it
 * also provides [summaryPath].
 */
class _InSummaryFallbackSource extends FileBasedSource
    implements InSummarySource {
  @override
  final String summaryPath;

  _InSummaryFallbackSource(JavaFile file, Uri uri, this.summaryPath)
      : super(file, uri);
}
