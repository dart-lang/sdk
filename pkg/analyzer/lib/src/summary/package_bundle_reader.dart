import 'dart:io' as io;

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/context/cache.dart';
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/resynthesize.dart';
import 'package:analyzer/src/summary/summary_sdk.dart';
import 'package:analyzer/src/task/dart.dart';
import 'package:analyzer/task/dart.dart';
import 'package:analyzer/task/model.dart';
import 'package:path/path.dart' as pathos;

/**
 * If [uri] has the `package` scheme in form of `package:pkg/file.dart`,
 * return the `pkg` name.  Otherwise return `null`.
 */
String _getPackageName(Uri uri) {
  if (uri.scheme != 'package') {
    return null;
  }
  String path = uri.path;
  int index = path.indexOf('/');
  if (index == -1) {
    return null;
  }
  return path.substring(0, index);
}

/**
 * The [ResultProvider] that provides results from input package summaries.
 */
class InputPackagesResultProvider extends ResultProvider {
  final InternalAnalysisContext _context;
  final Map<String, String> _packageSummaryInputs;

  _FileBasedSummaryResynthesizer _resynthesizer;
  SummaryResultProvider _sdkProvider;

  InputPackagesResultProvider(this._context, this._packageSummaryInputs) {
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
        _packageSummaryInputs.values.toList());
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
      String sourcePackageName = _getPackageName(uri);
      if (!_packageSummaryInputs.containsKey(sourcePackageName)) {
        return false;
      }
      // Provide known results.
      String uriString = uri.toString();
      if (result == LIBRARY_ELEMENT1 ||
          result == LIBRARY_ELEMENT2 ||
          result == LIBRARY_ELEMENT3 ||
          result == LIBRARY_ELEMENT4 ||
          result == LIBRARY_ELEMENT5 ||
          result == LIBRARY_ELEMENT6 ||
          result == LIBRARY_ELEMENT7 ||
          result == LIBRARY_ELEMENT8 ||
          result == LIBRARY_ELEMENT ||
          false) {
        LibraryElement libraryElement =
            _resynthesizer.getLibraryElement(uriString);
        entry.setValue(result, libraryElement, TargetedResult.EMPTY_LIST);
        return true;
      } else if (result == READY_LIBRARY_ELEMENT2 ||
          result == READY_LIBRARY_ELEMENT5 ||
          result == READY_LIBRARY_ELEMENT6) {
        entry.setValue(result, true, TargetedResult.EMPTY_LIST);
        return true;
      } else if (result == SOURCE_KIND) {
        if (_resynthesizer.linkedMap.containsKey(uriString)) {
          entry.setValue(result, SourceKind.LIBRARY, TargetedResult.EMPTY_LIST);
          return true;
        }
        if (_resynthesizer.unlinkedMap.containsKey(uriString)) {
          entry.setValue(result, SourceKind.PART, TargetedResult.EMPTY_LIST);
          return true;
        }
        return false;
      }
    }
    return false;
  }
}

/**
 * The [UriResolver] that knows about sources that are parts of packages which
 * are served from their summaries.
 */
class InSummaryPackageUriResolver extends UriResolver {
  final Map<String, String> _packageSummaryInputs;

  InSummaryPackageUriResolver(this._packageSummaryInputs);

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) {
    actualUri ??= uri;
    String packageName = _getPackageName(actualUri);
    if (_packageSummaryInputs.containsKey(packageName)) {
      return new _InSummarySource(actualUri);
    }
    return null;
  }
}

/**
 * A concrete resynthesizer that serves summaries from given file paths.
 */
class _FileBasedSummaryResynthesizer extends SummaryResynthesizer {
  final Map<String, UnlinkedUnit> unlinkedMap = <String, UnlinkedUnit>{};
  final Map<String, LinkedLibrary> linkedMap = <String, LinkedLibrary>{};

  _FileBasedSummaryResynthesizer(
      SummaryResynthesizer parent,
      AnalysisContext context,
      TypeProvider typeProvider,
      SourceFactory sourceFactory,
      bool strongMode,
      List<String> summaryPaths)
      : super(parent, context, typeProvider, sourceFactory, strongMode) {
    summaryPaths.forEach(_fillMaps);
  }

  @override
  LinkedLibrary getLinkedSummary(String uri) {
    return linkedMap[uri];
  }

  @override
  UnlinkedUnit getUnlinkedSummary(String uri) {
    return unlinkedMap[uri];
  }

  @override
  bool hasLibrarySummary(String uri) {
    return linkedMap.containsKey(uri);
  }

  void _fillMaps(String path) {
    io.File file = new io.File(path);
    List<int> buffer = file.readAsBytesSync();
    PackageBundle bundle = new PackageBundle.fromBuffer(buffer);
    for (int i = 0; i < bundle.unlinkedUnitUris.length; i++) {
      unlinkedMap[bundle.unlinkedUnitUris[i]] = bundle.unlinkedUnits[i];
    }
    for (int i = 0; i < bundle.linkedLibraryUris.length; i++) {
      linkedMap[bundle.linkedLibraryUris[i]] = bundle.linkedLibraries[i];
    }
  }
}

/**
 * A placeholder of a source that is part of a package whose analysis results
 * are served from its summary.  This source uses its URI as [fullName] and has
 * empty contents.
 */
class _InSummarySource extends Source {
  final Uri uri;

  _InSummarySource(this.uri);

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
      object is _InSummarySource && object.uri == uri;

  @override
  bool exists() => true;

  @override
  Uri resolveRelativeUri(Uri relativeUri) {
    Uri baseUri = uri;
    return baseUri.resolveUri(relativeUri);
  }

  @override
  String toString() => uri.toString();
}
