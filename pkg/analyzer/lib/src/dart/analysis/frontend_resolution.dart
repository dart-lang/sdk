import 'dart:async';
import 'dart:convert';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/kernel_metadata.dart';
import 'package:analyzer/src/fasta/resolution_storer.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:front_end/src/api_prototype/byte_store.dart';
import 'package:front_end/src/api_prototype/compilation_message.dart';
import 'package:front_end/src/api_prototype/compiler_options.dart';
import 'package:front_end/src/api_prototype/file_system.dart' as front_end;
import 'package:front_end/src/base/libraries_specification.dart';
import 'package:front_end/src/base/performance_logger.dart';
import 'package:front_end/src/base/processed_options.dart';
import 'package:front_end/src/fasta/builder/builder.dart';
import 'package:front_end/src/fasta/builder/library_builder.dart';
import 'package:front_end/src/fasta/compiler_context.dart';
import 'package:front_end/src/fasta/dill/dill_target.dart';
import 'package:front_end/src/fasta/kernel/kernel_target.dart';
import 'package:front_end/src/fasta/kernel/metadata_collector.dart';
import 'package:front_end/src/fasta/source/diet_listener.dart';
import 'package:front_end/src/fasta/source/source_library_builder.dart';
import 'package:front_end/src/fasta/source/source_loader.dart';
import 'package:front_end/src/fasta/source/stack_listener.dart';
import 'package:front_end/src/fasta/target_implementation.dart';
import 'package:front_end/src/fasta/type_inference/type_inference_engine.dart';
import 'package:front_end/src/fasta/type_inference/type_inference_listener.dart';
import 'package:front_end/src/fasta/uri_translator.dart';
import 'package:front_end/src/fasta/uri_translator_impl.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/target/targets.dart';
import 'package:kernel/type_environment.dart';
import 'package:package_config/packages.dart';
import 'package:package_config/src/packages_impl.dart';
import 'package:path/path.dart' as pathos;

/// Resolution information in a single function body.
class CollectedResolution {
  final Map<int, ResolutionData<DartType, int, Node, int>> kernelData = {};
}

/// The compilation result for a single file.
class FileCompilationResult {
  /// The file system URI of the file.
  final Uri fileUri;

  /// The list of resolution for each code block, e.g function body.
  final List<CollectedResolution> resolutions;

  /// The list of all FrontEnd errors in the file.
  final List<CompilationMessage> errors;

  FileCompilationResult(this.fileUri, this.resolutions, this.errors);
}

/// The wrapper around FrontEnd compiler that can be used incrementally.
///
/// When the client needs the kernel, resolution information, and errors for
/// a library, it should call [getResolution].  The compiler will compile the library
/// and the transitive closure of its dependencies.  The results are cached,
/// so the next invocation for a dependency will be served from the cache.
///
/// If a file is changed, [invalidate] should be invoked.  This will invalidate
/// the file, its library, and the transitive closure of dependencies.  So, the
/// next invocation of [getResolution] will recompile libraries required for the
/// requested library.
class FrontEndCompiler {
  static const MSG_PENDING_COMPILE =
      'A compile() invocation is still executing.';

  /// Options used by the kernel compiler.
  final ProcessedOptions _options;

  /// The logger to report compilation progress.
  final PerformanceLog _logger;

  /// The [FileSystem] to access file during compilation.
  final front_end.FileSystem _fileSystem;

  /// The object that knows how to resolve "package:" and "dart:" URIs.
  final UriTranslator uriTranslator;

  /// The listener / recorder for compilation errors produced by the compiler.
  final _ErrorListener _errorListener;

  /// The [Component] with currently valid libraries. When a file is invalidated,
  /// we remove the file, its library, and everything affected from [_component].
  Component _component = new Component();

  /// Each key is the file system URI of a library.
  /// Each value is the libraries that directly depend on the key library.
  final Map<Uri, Set<Uri>> _directLibraryDependencies = {};

  /// Each key is the file system URI of a library.
  /// Each value is the [Library] that is still in the [_component].
  final Map<Uri, Library> _uriToLibrary = {};

  /// Each key is the file system URI of a part.
  /// Each value is the file system URI of the library that sources the part.
  final Map<Uri, Uri> _partToLibrary = {};

  /// Whether [getResolution] is executing.
  bool _isCompileExecuting = false;

  factory FrontEndCompiler(
      PerformanceLog logger,
      ByteStore byteStore,
      AnalysisOptions analysisOptions,
      Folder sdkFolder,
      SourceFactory sourceFactory,
      FileSystemState fsState,
      pathos.Context pathContext) {
    // Prepare SDK libraries.
    Map<String, LibraryInfo> dartLibraries = {};
    {
      DartSdk dartSdk = sourceFactory.dartSdk;
      dartSdk.sdkLibraries.forEach((sdkLibrary) {
        var dartUri = sdkLibrary.shortName;
        var name = Uri.parse(dartUri).path;
        var path = dartSdk.mapDartUri(dartUri).fullName;
        var fileUri = pathContext.toUri(path);
        dartLibraries[name] = new LibraryInfo(name, fileUri, const []);
      });
    }

    // Prepare packages.
    Packages packages = Packages.noPackages;
    {
      Map<String, List<Folder>> packageMap = sourceFactory.packageMap;
      if (packageMap != null) {
        var map = <String, Uri>{};
        for (var name in packageMap.keys) {
          map[name] = packageMap[name].first.toUri();
        }
        packages = new MapPackages(map);
      }
    }

    // TODO(scheglov) Should we restore this?
//    // Try to find the SDK outline.
//    // It is not used for unit testing, we compile SDK sources.
//    // But for running shared tests we need the patched SDK.
//    List<int> sdkOutlineBytes;
//    if (sdkFolder != null) {
//      try {
//        sdkOutlineBytes = sdkFolder
//            .getChildAssumingFile('vm_platform_strong.dill')
//            .readAsBytesSync();
//      } catch (_) {}
//    }

    var uriTranslator = new UriTranslatorImpl(
        new TargetLibrariesSpecification('none', dartLibraries), packages);
    var errorListener = new _ErrorListener();
    var options = new CompilerOptions()
      ..target = new _AnalyzerTarget(
          new TargetFlags(strongMode: analysisOptions.strongMode))
      ..reportMessages = false
      ..logger = logger
      ..fileSystem = new _FileSystemAdaptor(fsState, pathContext)
      ..byteStore = byteStore
      ..onError = errorListener.onError;
    var processedOptions = new ProcessedOptions(options);

    return new FrontEndCompiler._(
        processedOptions, uriTranslator, errorListener);
  }

  FrontEndCompiler._(this._options, this.uriTranslator, this._errorListener)
      : _logger = _options.logger,
        _fileSystem = _options.fileSystem;

  /// Return the outline of the library with the given absolute [uri], and
  /// everything it depends on.
  ///
  /// If there is the cached outline for the library (computed directly, or as
  /// a result of computing the outline of another library), it will be
  /// returned quickly.
  ///
  /// Throw [StateError] if another compilation is pending.
  Future<LibraryOutlineResult> getOutline(Uri uri) {
    if (_isCompileExecuting) {
      throw new StateError(MSG_PENDING_COMPILE);
    }
    _isCompileExecuting = true;

    // TODO(scheglov) Do we need a map?
    if (_component.root.hasChild('$uri')) {
      _isCompileExecuting = false;
      // TODO(scheglov) Can we keep the same instance?
      var types = new TypeEnvironment(
          new CoreTypes(_component), new ClassHierarchy(_component));
      var result = new LibraryOutlineResult(_component, types);
      return new Future.value(result);
    }

    return _runWithFrontEndContext('Compute outline', () async {
      try {
        var dillTarget =
            new DillTarget(_options.ticker, uriTranslator, _options.target);

        // Append all libraries what we still have in the current component.
        await _logger.runAsync('Load dill libraries', () async {
          dillTarget.loader.appendLibraries(_component);
          await dillTarget.buildOutlines();
        });

        // Create the target for computing the outline of the library.
        var kernelTarget = new KernelTarget(
            _fileSystem, true, dillTarget, uriTranslator,
            metadataCollector: new AnalyzerMetadataCollector());
        kernelTarget.read(uri);

        // Compute new outlines.
        var newComponent = await _logger.runAsync('Compile', () async {
          return await kernelTarget.buildOutlines(nameRoot: _component.root);
        });

        // Add new libraries to the current component.
        if (newComponent != null) {
          // When a file is used in a `part` directive of a library, but does
          // not have a `part of` itself, we get this file both as a part,
          // and as a library. This causes an exception later in resolution.
          var partFileUris = new Set<Uri>();
          for (var library in newComponent.libraries) {
            var libraryFileUri = library.fileUri;
            for (var part in library.parts) {
              var partFileUri = libraryFileUri.resolve(part.partUri);
              if (partFileUri != libraryFileUri) {
                partFileUris.add(partFileUri);
              }
            }
          }
          // Do add new libraries.
          for (var library in newComponent.libraries) {
            if (!partFileUris.contains(library.fileUri)) {
              Uri uri = library.importUri;
              if (!_component.root.hasChild('$uri')) {
                _component.root.getChildFromUri(uri).bindTo(library.reference);
                library.computeCanonicalNames();
                _component.libraries.add(library);
              }
            }
          }
        }

        _logger.run('Compute dependencies', _computeDependencies);

        // TODO(scheglov) Can we keep the same instance?
        var types = new TypeEnvironment(
            new CoreTypes(_component), new ClassHierarchy(_component));
        return new LibraryOutlineResult(_component, types);
      } finally {
        _isCompileExecuting = false;
      }
    });
  }

  /// Compute resolution for the library with the given absolute [uri] and
  /// all its parts.
  ///
  /// Throw [StateError] if another compilation is pending.
  Future<LibraryCompilationResult> getResolution(Uri uri) {
    if (_isCompileExecuting) {
      throw new StateError(MSG_PENDING_COMPILE);
    }
    _isCompileExecuting = true;

    return _runWithFrontEndContext('Compile', () async {
      try {
        // Remove the requested library outline from the component.
        Library libraryOutline;
        for (var library in _component.libraries) {
          if (library.importUri == uri) {
            libraryOutline = library;
            _component.libraries.remove(library);
            _component.root.removeChild('$uri');
            break;
          }
        }
        if (libraryOutline == null) {
          throw new StateError('Expected to find $uri in the component.');
        }
        libraryOutline.canonicalName.getChild('IntWrapper');

        var dillTarget =
            new DillTarget(_options.ticker, uriTranslator, _options.target);

        // Append all libraries what we still have in the current component.
        await _logger.runAsync('Load dill libraries', () async {
          dillTarget.loader.appendLibraries(_component);
          await dillTarget.buildOutlines();
        });

        // Create the target to compile the library.
        var kernelTarget = new _AnalyzerKernelTarget(_fileSystem, dillTarget,
            uriTranslator, new AnalyzerMetadataCollector());
        kernelTarget.read(uri);

        // Resolve the requested library.
        Component newComponent = await _logger.runAsync('Compile', () async {
          await kernelTarget.buildOutlines(nameRoot: _component.root);
          return await kernelTarget.buildComponent();
        });

        // Put the library outline back into the current component.
        _component.root.adoptChild(libraryOutline.canonicalName);
        _component.libraries.add(libraryOutline);

        // Compute canonical names for the resolved library.
        for (var library in newComponent.libraries) {
          if (library.importUri == uri) {
            library.reference.canonicalName = _component.root.getChild('$uri');
            library.computeCanonicalNames();
            break;
          }
        }

        // TODO(scheglov) Can we keep the same instance?
        var types = new TypeEnvironment(
            new CoreTypes(_component), new ClassHierarchy(_component));

        Uri libraryFileUri = libraryOutline.fileUri;
        var libraryResolutions = kernelTarget.resolutions[libraryFileUri];
        if (libraryResolutions == null) {
          throw new StateError('Expected to find $uri in resolutions.');
        }
        // TODO(scheglov) Check that we have exactly one resolution?
        var files = <Uri, FileCompilationResult>{};

        void addFileResult(Uri fileUri) {
          if (libraryResolutions != null) {
            files[fileUri] = new FileCompilationResult(
                fileUri,
                libraryResolutions[fileUri] ?? [],
                _errorListener.fileUriToErrors[fileUri] ?? []);
          }
        }

        addFileResult(libraryFileUri);
        for (var part in libraryOutline.parts) {
          addFileResult(libraryFileUri.resolve(part.partUri));
        }
        _errorListener.fileUriToErrors.clear();

        return new LibraryCompilationResult(
            _component, types, libraryOutline.importUri, libraryOutline, files);
      } finally {
        _isCompileExecuting = false;
      }
    });
  }

  /// Invalidate the file with the given file [uri], its library and the
  /// transitive the of libraries that use it.  The next time when any of these
  /// libraries is be requested in [getResolution], it will be recompiled again.
  void invalidate(Uri uri) {
    void invalidateLibrary(Uri libraryUri) {
      Library library = _uriToLibrary.remove(libraryUri);
      if (library == null) return;

      // Invalidate the library.
      _component.libraries.remove(library);
      _component.root.removeChild('${library.importUri}');
      _component.uriToSource.remove(libraryUri);

      // Recursively invalidate dependencies.
      Set<Uri> directDependencies =
          _directLibraryDependencies.remove(libraryUri);
      directDependencies?.forEach(invalidateLibrary);
    }

    Uri libraryUri = _partToLibrary.remove(uri) ?? uri;
    invalidateLibrary(libraryUri);
  }

  /// Recompute [_directLibraryDependencies] for the current [_component].
  void _computeDependencies() {
    _directLibraryDependencies.clear();
    _uriToLibrary.clear();
    _partToLibrary.clear();

    void processLibrary(Library library) {
      if (_uriToLibrary.containsKey(library.fileUri)) {
        return;
      }
      _uriToLibrary[library.fileUri] = library;

      // Remember libraries for parts.
      for (var part in library.parts) {
        _partToLibrary[library.fileUri.resolve(part.partUri)] = library.fileUri;
      }

      // Record reverse dependencies.
      for (LibraryDependency dependency in library.dependencies) {
        Library targetLibrary = dependency.targetLibrary;
        _directLibraryDependencies
            .putIfAbsent(targetLibrary.fileUri, () => new Set<Uri>())
            .add(library.fileUri);
        processLibrary(targetLibrary);
      }
    }

    // Record dependencies for every library in the component.
    _component.libraries.forEach(processLibrary);
  }

  Future<T> _runWithFrontEndContext<T>(String msg, Future<T> f()) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    return await CompilerContext.runWithOptions(_options, (context) {
      context.disableColors();
      return _logger.runAsync(msg, f);
    });
  }
}

/// The compilation result for a single library.
class LibraryCompilationResult {
  /// The full current [Component]. It has all libraries that are required by
  /// this library, but might also have other libraries, that are not required.
  ///
  /// The object is mutable, and is changed when files are invalidated.
  final Component component;

  /// The [TypeEnvironment] for the [component].
  final TypeEnvironment types;

  /// The absolute URI of the library.
  final Uri uri;

  /// The kernel [Library] of the library.
  final Library kernel;

  /// The map from file system URIs to results for the defining unit and parts.
  final Map<Uri, FileCompilationResult> files;

  LibraryCompilationResult(
      this.component, this.types, this.uri, this.kernel, this.files);
}

/// The outline result for a single library.
class LibraryOutlineResult {
  /// The full current [Component]. It has all libraries that are required by
  /// this library, but might also have other libraries, that are not required.
  ///
  /// The object is mutable, and is changed when files are invalidated.
  final Component component;

  /// The [TypeEnvironment] for the [component].
  final TypeEnvironment types;

  LibraryOutlineResult(this.component, this.types);
}

/// The [DietListener] that record resolution information.
class _AnalyzerDietListener extends DietListener {
  final Map<Uri, List<CollectedResolution>> _resolutions;

  _AnalyzerDietListener(
      SourceLibraryBuilder library,
      ClassHierarchy hierarchy,
      CoreTypes coreTypes,
      TypeInferenceEngine typeInferenceEngine,
      this._resolutions)
      : super(library, hierarchy, coreTypes, typeInferenceEngine);

  StackListener createListener(
      ModifierBuilder builder, Scope memberScope, bool isInstanceMember,
      [Scope formalParameterScope,
      TypeInferenceListener<int, int, Node, int> listener]) {
    ResolutionStorer storer;
    var fileResolutions = _resolutions[builder.fileUri];
    if (fileResolutions == null) {
      fileResolutions = <CollectedResolution>[];
      _resolutions[builder.fileUri] = fileResolutions;
    }
    var resolution = new CollectedResolution();
    fileResolutions.add(resolution);
    storer = new ResolutionStorer(resolution.kernelData);
    return super.createListener(
        builder, memberScope, isInstanceMember, formalParameterScope, storer);
  }
}

/// The [KernelTarget] that records resolution information.
class _AnalyzerKernelTarget extends KernelTarget {
  final Map<Uri, Map<Uri, List<CollectedResolution>>> resolutions = {};

  _AnalyzerKernelTarget(front_end.FileSystem fileSystem, DillTarget dillTarget,
      UriTranslator uriTranslator, MetadataCollector metadataCollector)
      : super(fileSystem, true, dillTarget, uriTranslator,
            metadataCollector: metadataCollector);

  @override
  _AnalyzerSourceLoader<Library> createLoader() {
    return new _AnalyzerSourceLoader<Library>(fileSystem, this, resolutions);
  }
}

/// The [SourceLoader] that record resolution information.
class _AnalyzerSourceLoader<L> extends SourceLoader<L> {
  final Map<Uri, Map<Uri, List<CollectedResolution>>> _resolutions;

  _AnalyzerSourceLoader(front_end.FileSystem fileSystem,
      TargetImplementation target, this._resolutions)
      : super(fileSystem, true, target);

  @override
  _AnalyzerDietListener createDietListener(LibraryBuilder library) {
    var libraryResolutions = <Uri, List<CollectedResolution>>{};
    _resolutions[library.fileUri] = libraryResolutions;
    return new _AnalyzerDietListener(
        library, hierarchy, coreTypes, typeInferenceEngine, libraryResolutions);
  }
}

/**
 * [Target] for static analysis, with all features enabled.
 */
class _AnalyzerTarget extends NoneTarget {
  _AnalyzerTarget(TargetFlags flags) : super(flags);

  @override
  List<String> get extraRequiredLibraries => const <String>['dart:_internal'];

  @override
  bool enableNative(Uri uri) => true;
}

/// The listener for [CompilationMessage]s from FrontEnd.
class _ErrorListener {
  final Map<Uri, List<CompilationMessage>> fileUriToErrors = {};

  void onError(CompilationMessage error) {
    var fileUri = error.span.sourceUrl;
    fileUriToErrors.putIfAbsent(fileUri, () => []).add(error);
  }
}

/// Adapter of [FileSystemState] to [front_end.FileSystem].
class _FileSystemAdaptor implements front_end.FileSystem {
  final FileSystemState fsState;
  final pathos.Context pathContext;

  _FileSystemAdaptor(this.fsState, this.pathContext);

  @override
  front_end.FileSystemEntity entityForUri(Uri uri) {
    if (uri.isScheme('file')) {
      var path = pathContext.fromUri(uri);
      var file = fsState.getFileForPath(path);
      return new _FileSystemEntityAdaptor(uri, file);
    } else {
      throw new front_end.FileSystemException(
          uri, 'Only file:// URIs are supported, but $uri is given.');
    }
  }
}

/// Adapter of [FileState] to [front_end.FileSystemEntity].
class _FileSystemEntityAdaptor implements front_end.FileSystemEntity {
  final Uri uri;
  final FileState file;

  _FileSystemEntityAdaptor(this.uri, this.file);

  @override
  Future<bool> exists() async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    return file.exists;
  }

  @override
  Future<List<int>> readAsBytes() async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    // TODO(scheglov) Optimize.
    return utf8.encode(file.content);
  }

  @override
  Future<String> readAsString() async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    return file.content;
  }
}
