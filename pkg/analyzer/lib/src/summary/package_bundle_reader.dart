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
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/resynthesize.dart';
import 'package:analyzer/src/task/dart.dart';
import 'package:analyzer/src/util/fast_uri.dart';
import 'package:analyzer/task/dart.dart';
import 'package:analyzer/task/general.dart';
import 'package:analyzer/task/model.dart';
import 'package:path/path.dart' as pathos;

/**
 * The [ResultProvider] that provides results from input package summaries.
 */
class InputPackagesResultProvider extends ResynthesizerResultProvider {
  InputPackagesResultProvider(
      InternalAnalysisContext context, SummaryDataStore dataStore)
      : super(context, dataStore) {
    AnalysisContext sdkContext = context.sourceFactory.dartSdk.context;
    createResynthesizer(sdkContext, sdkContext.typeProvider);
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
 *
 * TODO(scheglov) rename to `InSummaryUriResolver` - it's not `package:` specific.
 */
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
  bool get isInSystemLibrary => uri.scheme == DartUriResolver.DART_SCHEME;

  @override
  int get modificationStamp => 0;

  @override
  String get shortName => pathos.basename(fullName);

  @override
  UriKind get uriKind => UriKind.PACKAGE_URI;

  @override
  bool operator ==(Object object) => object is Source && object.uri == uri;

  @override
  bool exists() => true;

  @override
  String toString() => uri.toString();
}

/**
 * The [ResultProvider] that provides results using summary resynthesizer.
 */
abstract class ResynthesizerResultProvider extends ResultProvider {
  final InternalAnalysisContext context;
  final SummaryDataStore _dataStore;

  _FileBasedSummaryResynthesizer _resynthesizer;
  ResynthesizerResultProvider _sdkProvider;

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
    if (_sdkProvider != null && _sdkProvider.compute(entry, result)) {
      return true;
    }
    AnalysisTarget target = entry.target;
    // Check whether there are results for the source.
    if (!hasResultsForSource(target.librarySource ?? target.source)) {
      return false;
    }
    // Constant expressions are always resolved in summaries.
    if (result == CONSTANT_EXPRESSION_RESOLVED &&
        target is ConstantEvaluationTarget) {
      entry.setValue(result, true, TargetedResult.EMPTY_LIST);
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
        entry.setValue(result, libraryElement, TargetedResult.EMPTY_LIST);
        return true;
      } else if (result == READY_LIBRARY_ELEMENT2 ||
          result == READY_LIBRARY_ELEMENT6 ||
          result == READY_LIBRARY_ELEMENT7) {
        entry.setValue(result, true, TargetedResult.EMPTY_LIST);
        return true;
      } else if (result == SOURCE_KIND) {
        if (_dataStore.linkedMap.containsKey(uriString)) {
          entry.setValue(result, SourceKind.LIBRARY, TargetedResult.EMPTY_LIST);
          return true;
        }
        if (_dataStore.unlinkedMap.containsKey(uriString)) {
          entry.setValue(result, SourceKind.PART, TargetedResult.EMPTY_LIST);
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
          entry.setValue(result, librarySources, TargetedResult.EMPTY_LIST);
          return true;
        }
        return false;
      } else if (result == LINE_INFO) {
        UnlinkedUnit unlinkedUnit = _dataStore.unlinkedMap[uriString];
        List<int> lineStarts = unlinkedUnit.lineStarts;
        if (lineStarts.isNotEmpty) {
          LineInfo lineInfo = new LineInfo(lineStarts);
          entry.setValue(result, lineInfo, TargetedResult.EMPTY_LIST);
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
          result == CREATED_RESOLVED_UNIT11 ||
          result == CREATED_RESOLVED_UNIT12) {
        entry.setValue(result, true, TargetedResult.EMPTY_LIST);
        return true;
      }
      if (result == COMPILATION_UNIT_ELEMENT) {
        String libraryUri = target.library.uri.toString();
        String unitUri = target.unit.uri.toString();
        CompilationUnitElement unit = resynthesizer.getElement(
            new ElementLocationImpl.con3(<String>[libraryUri, unitUri]));
        if (unit != null) {
          entry.setValue(result, unit, TargetedResult.EMPTY_LIST);
          return true;
        }
      }
    } else if (target is VariableElement) {
      if (result == PROPAGATED_VARIABLE || result == INFERRED_STATIC_VARIABLE) {
        entry.setValue(result, target, TargetedResult.EMPTY_LIST);
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
  void createResynthesizer(
      InternalAnalysisContext sdkContext, TypeProvider typeProvider) {
    // Set the type provider to prevent the context from computing it.
    context.typeProvider = typeProvider;
    // Create a chained resynthesizer.
    _sdkProvider = sdkContext?.resultProvider;
    _resynthesizer = new _FileBasedSummaryResynthesizer(
        _sdkProvider?.resynthesizer,
        context,
        typeProvider,
        context.sourceFactory,
        context.analysisOptions.strongMode,
        _dataStore);
  }

  /**
   * Return `true` if this result provider can provide a result for the
   * given [source].  The provider must ensure that [addBundle] is invoked for
   * every bundle that would be required to provide results for the [source].
   */
  bool hasResultsForSource(Source source);
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
   * List of dependency information for the package bundles in this
   * [SummaryDataStore], in a form that is ready to store in a newly generated
   * summary.  Computing this information has nonzero cost, so it is only
   * recorded if the [SummaryDataStore] is constructed with the argument
   * `recordDependencies`.  Otherwise `null`.
   */
  final List<PackageDependencyInfoBuilder> dependencies;

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
   * Create a [SummaryDataStore] and populate it with the summaries in
   * [summaryPaths].  If [recordDependencyInfo] is `true`, record
   * [PackageDependencyInfo] for each summary, for later access via
   * [dependencies].
   */
  SummaryDataStore(Iterable<String> summaryPaths,
      {bool recordDependencyInfo: false})
      : dependencies =
            recordDependencyInfo ? <PackageDependencyInfoBuilder>[] : null {
    summaryPaths.forEach(_fillMaps);
  }

  /**
   * Add the given [bundle] loaded from the file with the given [path].
   */
  void addBundle(String path, PackageBundle bundle) {
    bundles.add(bundle);
    if (dependencies != null) {
      Set<String> includedPackageNames = new Set<String>();
      bool includesDartUris = false;
      bool includesFileUris = false;
      for (String uriString in bundle.unlinkedUnitUris) {
        Uri uri = FastUri.parse(uriString);
        String scheme = uri.scheme;
        if (scheme == 'package') {
          List<String> pathSegments = uri.pathSegments;
          includedPackageNames.add(pathSegments.isEmpty ? '' : pathSegments[0]);
        } else if (scheme == 'file') {
          includesFileUris = true;
        } else if (scheme == 'dart') {
          includesDartUris = true;
        }
      }
      dependencies.add(new PackageDependencyInfoBuilder(
          includedPackageNames: includedPackageNames.toList()..sort(),
          includesDartUris: includesDartUris,
          includesFileUris: includesFileUris,
          apiSignature: bundle.apiSignature,
          summaryPath: path));
    }
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
      Uri libraryUri = FastUri.parse(unlinkedUnitUriString);
      for (String partUriString in unlinkedUnit.publicNamespace.parts) {
        Uri partUri = FastUri.parse(partUriString);
        String partAbsoluteUriString =
            resolveRelativeUri(libraryUri, partUri).toString();
        if (partAbsoluteUriString == unitUriString) {
          libraryUriStrings.add(unlinkedUnitUriString);
        }
      }
    });
    return libraryUriStrings.isNotEmpty ? libraryUriStrings : null;
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
