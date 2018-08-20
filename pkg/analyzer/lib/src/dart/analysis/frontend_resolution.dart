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
import 'package:front_end/src/fasta/compiler_context.dart';
import 'package:front_end/src/fasta/dill/dill_target.dart';
import 'package:front_end/src/fasta/kernel/kernel_shadow_ast.dart';
import 'package:front_end/src/fasta/kernel/kernel_target.dart';
import 'package:front_end/src/fasta/kernel/metadata_collector.dart';
import 'package:front_end/src/fasta/source/diet_listener.dart';
import 'package:front_end/src/fasta/source/outline_listener.dart';
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
import 'package:package_config/packages.dart';
import 'package:package_config/src/packages_impl.dart';
import 'package:path/path.dart' as pathos;

/// Resolution information in a single function body.
class CollectedResolution {
  final Map<int, ResolutionData> kernelData = {};

  final Map<TypeParameter, int> typeVariableDeclarations =
      new Map<TypeParameter, int>.identity();
}

/// The compilation result for a single file.
class FileCompilationResult {
  /// The file system URI of the file.
  final Uri fileUri;

  /// The collected resolution for the file.
  final CollectedResolution resolution;

  /// The list of all FrontEnd errors in the file.
  final List<CompilationMessage> errors;

  FileCompilationResult(this.fileUri, this.resolution, this.errors);
}

/// The wrapper around FrontEnd compiler that can be used incrementally.
///
/// When the client needs the kernel, resolution information, and errors for
/// a library, it should call [compile].  The compiler will compile the library
/// and the transitive closure of its dependencies.  The results are cached,
/// so the next invocation for a dependency will be served from the cache.
///
/// If a file is changed, [invalidate] should be invoked.  This will invalidate
/// the file, its library, and the transitive closure of dependencies.  So, the
/// next invocation of [compile] will recompile libraries required for the
/// requested library.
class FrontEndCompiler {
  static const MSG_PENDING_COMPILE =
      'A compile() invocation is still executing.';

  /// Options used by the kernel compiler.
  final CompilerOptions _compilerOptions;

  /// The logger to report compilation progress.
  final PerformanceLog _logger;

  /// The [FileSystem] to access file during compilation.
  final front_end.FileSystem _fileSystem;

  /// The object that knows how to resolve "package:" and "dart:" URIs.
  final UriTranslator uriTranslator;

  /// The listener / recorder for compilation errors produced by the compiler.
  final _ErrorListener _errorListener;

  /// Each key is the absolute URI of a library.
  /// Each value is the compilation result of the key library.
  final Map<Uri, LibraryCompilationResult> _results = {};

  /// Index of metadata in [_component].
  final AnalyzerMetadataIndex _metadataIndex = new AnalyzerMetadataIndex();

  /// The [Component] with currently valid libraries. When a file is invalidated,
  /// we remove the file, its library, and everything affected from [_component].
  Component _component = new Component();

  /// The [DillTarget] that is filled with [_component] libraries before
  /// compilation of a new library.
  DillTarget _dillTarget;

  /// Each key is the file system URI of a library.
  /// Each value is the libraries that directly depend on the key library.
  final Map<Uri, Set<Uri>> _directLibraryDependencies = {};

  /// Each key is the file system URI of a library.
  /// Each value is the [Library] that is still in the [_component].
  final Map<Uri, Library> _uriToLibrary = {};

  /// Each key is the file system URI of a part.
  /// Each value is the file system URI of the library that sources the part.
  final Map<Uri, Uri> _partToLibrary = {};

  /// Whether [compile] is executing.
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
    var compilerOptions = new CompilerOptions()
      ..target = new _AnalyzerTarget(new TargetFlags(strongMode: true),
          enableSuperMixins: analysisOptions.enableSuperMixins)
      ..reportMessages = false
      ..logger = logger
      ..fileSystem = new _FileSystemAdaptor(fsState, pathContext)
      ..byteStore = byteStore
      ..onError = errorListener.onError;

    return new FrontEndCompiler._(
        compilerOptions, uriTranslator, errorListener);
  }

  FrontEndCompiler._(
      this._compilerOptions, this.uriTranslator, this._errorListener)
      : _logger = _compilerOptions.logger,
        _fileSystem = _compilerOptions.fileSystem;

  /// Compile the library with the given absolute [uri], and everything it
  /// depends on. Return the result of the requested library compilation.
  ///
  /// If there is the cached result for the library (compiled directly, or as
  /// a result of compilation of another library), it will be returned quickly.
  ///
  /// Throw [StateError] if another compilation is pending.
  Future<LibraryCompilationResult> compile(Uri uri) {
    if (_isCompileExecuting) {
      throw new StateError(MSG_PENDING_COMPILE);
    }
    _isCompileExecuting = true;

    {
      LibraryCompilationResult result = _results[uri];
      if (result != null) {
        _isCompileExecuting = false;
        return new Future.value(result);
      }
    }

    return _runWithFrontEndContext('Compile', uri, (processedOptions) async {
      try {
        // Initialize the dill target once.
        if (_dillTarget == null) {
          _dillTarget = new DillTarget(
            processedOptions.ticker,
            uriTranslator,
            processedOptions.target,
          );
        }

        // Append new libraries from the current component.
        await _logger.runAsync('Load dill libraries', () async {
          _dillTarget.loader.appendLibraries(_component,
              filter: (uri) => !_dillTarget.loader.builders.containsKey(uri));
          await _dillTarget.buildOutlines();
        });

        // Create the target to compile the library.
        var kernelTarget = new _AnalyzerKernelTarget(_fileSystem, _dillTarget,
            uriTranslator, new AnalyzerMetadataCollector());
        kernelTarget.read(uri);

        // Compile the entry point into the new component.
        _component = await _logger.runAsync('Compile', () async {
          await kernelTarget.buildOutlines(nameRoot: _component.root);
          Component newComponent = await kernelTarget.buildComponent();
          if (newComponent != null) {
            _metadataIndex.replaceComponent(newComponent);
            return newComponent;
          } else {
            return _component;
          }
        });

        _ShadowCleaner cleaner = new _ShadowCleaner();
        for (var library in _component.libraries) {
          if (!_results.containsKey(library.importUri)) {
            _component.computeCanonicalNamesForLibrary(library);
            library.accept(cleaner);
          }
        }

        _logger.run('Compute dependencies', _computeDependencies);

        // Add results for new libraries.
        for (var library in _component.libraries) {
          if (!_results.containsKey(library.importUri)) {
            Map<Uri, CollectedResolution> libraryResolutions =
                kernelTarget.resolutions[library.fileUri];

            var files = <Uri, FileCompilationResult>{};

            void addFileResult(Uri fileUri) {
              if (libraryResolutions != null) {
                files[fileUri] = new FileCompilationResult(
                    fileUri,
                    libraryResolutions[fileUri] ?? new CollectedResolution(),
                    _errorListener.fileUriToErrors[fileUri] ?? []);
              }
            }

            addFileResult(library.fileUri);
            for (var part in library.parts) {
              addFileResult(library.fileUri.resolve(part.partUri));
            }

            var libraryResult = new LibraryCompilationResult(
                _component, library.importUri, library, files);
            _results[library.importUri] = libraryResult;
          }
        }
        _errorListener.fileUriToErrors.clear();

        // The result must have been computed.
        return _results[uri];
      } finally {
        _isCompileExecuting = false;
      }
    });
  }

  /// Invalidate the file with the given file [uri], its library and the
  /// transitive the of libraries that use it.  The next time when any of these
  /// libraries is be requested in [compile], it will be recompiled again.
  void invalidate(Uri uri) {
    void invalidateLibrary(Uri libraryUri) {
      Library library = _uriToLibrary.remove(libraryUri);
      if (library == null) return;

      // Invalidate the library.
      _metadataIndex.invalidate(library);
      _component.libraries.remove(library);
      _component.root.removeChild('${library.importUri}');
      _component.uriToSource.remove(libraryUri);
      _dillTarget.loader.builders.remove(library.importUri);
      _dillTarget.loader.libraries.remove(library);
      _dillTarget.loader.uriToSource.remove(libraryUri);
      _results.remove(library.importUri);

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

  Future<T> _runWithFrontEndContext<T>(
      String msg, Uri input, Future<T> Function(ProcessedOptions) f) async {
    var processedOptions = new ProcessedOptions(_compilerOptions, [input]);
    return await CompilerContext.runWithOptions(processedOptions, (context) {
      context.disableColors();
      return _logger.runAsync(msg, () => f(processedOptions));
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

  /// The absolute URI of the library.
  final Uri uri;

  /// The kernel [Library] of the library.
  final Library kernel;

  /// The map from file system URIs to results for the defining unit and parts.
  final Map<Uri, FileCompilationResult> files;

  LibraryCompilationResult(this.component, this.uri, this.kernel, this.files);
}

/// The [DietListener] that record resolution information.
class _AnalyzerDietListener extends DietListener {
  final Map<Uri, ResolutionStorer> _storerMap = {};

  _AnalyzerDietListener(
      SourceLibraryBuilder library,
      ClassHierarchy hierarchy,
      CoreTypes coreTypes,
      TypeInferenceEngine typeInferenceEngine,
      Map<Uri, CollectedResolution> resolutions)
      : super(library, hierarchy, coreTypes, typeInferenceEngine) {
    for (var fileUri in resolutions.keys) {
      var resolution = resolutions[fileUri];
      _storerMap[fileUri] = new ResolutionStorer(
          resolution.kernelData, resolution.typeVariableDeclarations);
    }
  }

  StackListener createListener(
      ModifierBuilder builder, Scope memberScope, bool isInstanceMember,
      [Scope formalParameterScope,
      TypeInferenceListener<int, Node, int> listener]) {
    ResolutionStorer storer = _storerMap[builder.fileUri];
    return super.createListener(
        builder, memberScope, isInstanceMember, formalParameterScope, storer);
  }
}

/// The [KernelTarget] that records resolution information.
class _AnalyzerKernelTarget extends KernelTarget {
  final Map<Uri, Map<Uri, CollectedResolution>> resolutions = {};

  _AnalyzerKernelTarget(front_end.FileSystem fileSystem, DillTarget dillTarget,
      UriTranslator uriTranslator, MetadataCollector metadataCollector)
      : super(fileSystem, true, dillTarget, uriTranslator,
            metadataCollector: metadataCollector);

  @override
  _AnalyzerSourceLoader<Library> createLoader() {
    return new _AnalyzerSourceLoader<Library>(fileSystem, this, resolutions);
  }

  @override
  Declaration getDuplicatedFieldInitializerError(loader) {
    return loader.coreLibrary.getConstructor('Exception');
  }
}

/// [OutlineListener] that records resolution.
class _AnalyzerOutlineListener implements OutlineListener {
  final Uri fileUri;
  final CollectedResolution resolution;

  _AnalyzerOutlineListener(this.fileUri, this.resolution);

  @override
  void store(int offset, bool isSynthetic,
      {int importIndex, Node reference, DartType type}) {
//    if (fileUri.toString().endsWith('test.dart')) {
//      print('[store][offset: $offset][reference: $reference][type: $type]');
//    }
    var encodedLocation = 2 * offset + (isSynthetic ? 1 : 0);
    resolution.kernelData[encodedLocation] = new ResolutionData(
        isOutline: true,
        prefixInfo: importIndex,
        reference: reference,
        inferredType: type);
  }
}

/// The [SourceLoader] that record resolution information.
class _AnalyzerSourceLoader<L> extends SourceLoader<L> {
  final Map<Uri, CollectedResolution> _fileResolutions = {};
  final Map<Uri, Map<Uri, CollectedResolution>> _resolutions;

  _AnalyzerSourceLoader(front_end.FileSystem fileSystem,
      TargetImplementation target, this._resolutions)
      : super(fileSystem, true, target);

  @override
  _AnalyzerDietListener createDietListener(SourceLibraryBuilder library) {
    var libraryResolutions = <Uri, CollectedResolution>{};
    libraryResolutions[library.fileUri] = _fileResolution(library.fileUri);
    for (var part in library.parts) {
      libraryResolutions[part.fileUri] = _fileResolution(part.fileUri);
    }
    _resolutions[library.fileUri] = libraryResolutions;

    return new _AnalyzerDietListener(
        library, hierarchy, coreTypes, typeInferenceEngine, libraryResolutions);
  }

  @override
  OutlineListener createOutlineListener(Uri fileUri) {
    var resolution = _fileResolution(fileUri);
    return new _AnalyzerOutlineListener(fileUri, resolution);
  }

  @override
  Severity rewriteSeverity(severity, message, fileUri) => severity;

  CollectedResolution _fileResolution(Uri fileUri) {
    CollectedResolution resolution = _fileResolutions[fileUri];
    if (resolution == null) {
      resolution = new CollectedResolution();
      _fileResolutions[fileUri] = resolution;
    }
    return resolution;
  }
}

/**
 * [Target] for static analysis, with all features enabled.
 */
class _AnalyzerTarget extends NoneTarget {
  @override
  bool enableSuperMixins;

  _AnalyzerTarget(TargetFlags flags, {this.enableSuperMixins = false})
      : super(flags);

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
    return file.exists;
  }

  @override
  Future<List<int>> readAsBytes() async {
    _throwIfDoesNotExist();
    // TODO(scheglov) Optimize.
    return utf8.encode(file.content);
  }

  @override
  Future<String> readAsString() async {
    _throwIfDoesNotExist();
    return file.content;
  }

  void _throwIfDoesNotExist() {
    if (!file.exists) {
      throw new front_end.FileSystemException(uri, 'File not found');
    }
  }
}

/// Visitor that removes from shadow AST information that is not needed once
/// resolution is done, and causes memory leaks during incremental compilation.
class _ShadowCleaner extends RecursiveVisitor {
  @override
  visitField(Field node) {
    if (node is ShadowField) {
      node.inferenceNode = null;
      node.typeInferrer = null;
    }
    return super.visitField(node);
  }

  @override
  visitProcedure(Procedure node) {
    if (node is ShadowProcedure) {
      node.inferenceNode = null;
    }
    return super.visitProcedure(node);
  }
}
