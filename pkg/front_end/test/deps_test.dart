import 'dart:io';

import 'package:_fe_analyzer_shared/src/messages/severity.dart';
import 'package:expect/expect.dart' show Expect;
import 'package:front_end/src/api_prototype/compiler_options.dart';
import 'package:front_end/src/base/processed_options.dart';
import 'package:front_end/src/fasta/compiler_context.dart';
import 'package:front_end/src/fasta/dill/dill_target.dart';
import 'package:front_end/src/fasta/kernel/kernel_target.dart';
import 'package:front_end/src/fasta/ticker.dart';
import 'package:front_end/src/fasta/uri_translator.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/target/targets.dart';
import 'package:front_end/src/compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;
import "package:vm/target/vm.dart" show VmTarget;
import 'utils/io_utils.dart' show computeRepoDirUri;

final Uri repoDir = computeRepoDirUri();

Set<String> allowlistedExternalDartFiles = {
  "third_party/pkg/charcode/lib/ascii.dart",

  "third_party/pkg_tested/package_config/lib/package_config.dart",
  "third_party/pkg_tested/package_config/lib/package_config_types.dart",
  "third_party/pkg_tested/package_config/lib/src/discovery.dart",
  "third_party/pkg_tested/package_config/lib/src/errors.dart",
  "third_party/pkg_tested/package_config/lib/src/package_config_impl.dart",
  "third_party/pkg_tested/package_config/lib/src/package_config_io.dart",
  "third_party/pkg_tested/package_config/lib/src/package_config_json.dart",
  "third_party/pkg_tested/package_config/lib/src/package_config.dart",
  "third_party/pkg_tested/package_config/lib/src/packages_file.dart",
  "third_party/pkg_tested/package_config/lib/src/util.dart",

  // TODO(johnniwinther): Fix to allow dependency of package:package_config.
  "third_party/pkg_tested/package_config/lib/src/util_io.dart",

  // TODO(CFE-team): These files should not be included.
  // The package isn't even in pubspec.yaml.
  "pkg/meta/lib/meta.dart",
  "pkg/meta/lib/meta_meta.dart",
};

Future<void> main() async {
  Ticker ticker = new Ticker(isVerbose: false);
  CompilerOptions compilerOptions = getOptions();

  Uri dotPackagesUri = repoDir.resolve(".packages");
  if (!new File.fromUri(dotPackagesUri).existsSync()) {
    throw "Couldn't find .packages";
  }
  compilerOptions.packagesFileUri = dotPackagesUri;

  ProcessedOptions options = new ProcessedOptions(options: compilerOptions);

  Uri frontendLibUri = repoDir.resolve("pkg/front_end/lib/");
  List<FileSystemEntity> entities =
      new Directory.fromUri(frontendLibUri).listSync(recursive: true);
  for (FileSystemEntity entity in entities) {
    if (entity is File && entity.path.endsWith(".dart")) {
      options.inputs.add(entity.uri);
    }
  }

  List<Uri> result = await CompilerContext.runWithOptions<List<Uri>>(options,
      (CompilerContext c) async {
    UriTranslator uriTranslator = await c.options.getUriTranslator();
    DillTarget dillTarget =
        new DillTarget(ticker, uriTranslator, c.options.target);
    KernelTarget kernelTarget =
        new KernelTarget(c.fileSystem, false, dillTarget, uriTranslator);
    Uri platform = c.options.sdkSummary;
    if (platform != null) {
      var bytes = new File.fromUri(platform).readAsBytesSync();
      var platformComponent = loadComponentFromBytes(bytes);
      dillTarget.loader
          .appendLibraries(platformComponent, byteCount: bytes.length);
    }

    kernelTarget.setEntryPoints(c.options.inputs);
    await dillTarget.buildOutlines();
    await kernelTarget.loader.buildOutlines();
    return new List<Uri>.from(c.dependencies);
  });

  Set<Uri> otherDartUris = new Set<Uri>();
  Set<Uri> otherNonDartUris = new Set<Uri>();
  Set<Uri> frontEndUris = new Set<Uri>();
  Set<Uri> kernelUris = new Set<Uri>();
  Set<Uri> feAnalyzerSharedUris = new Set<Uri>();
  Set<Uri> dartPlatformUris = new Set<Uri>();
  Uri kernelUri = repoDir.resolve("pkg/kernel/");
  Uri feAnalyzerSharedUri = repoDir.resolve("pkg/_fe_analyzer_shared/");
  Uri platformUri1 = repoDir.resolve("sdk/lib/");
  Uri platformUri2 = repoDir.resolve("runtime/lib/");
  Uri platformUri3 = repoDir.resolve("runtime/bin/");
  for (Uri uri in result) {
    if (uri.toString().startsWith(frontendLibUri.toString())) {
      frontEndUris.add(uri);
    } else if (uri.toString().startsWith(kernelUri.toString())) {
      kernelUris.add(uri);
    } else if (uri.toString().startsWith(feAnalyzerSharedUri.toString())) {
      feAnalyzerSharedUris.add(uri);
    } else if (uri.toString().startsWith(platformUri1.toString()) ||
        uri.toString().startsWith(platformUri2.toString()) ||
        uri.toString().startsWith(platformUri3.toString())) {
      dartPlatformUris.add(uri);
    } else if (uri.toString().endsWith(".dart")) {
      otherDartUris.add(uri);
    } else {
      otherNonDartUris.add(uri);
    }
  }

  // * Everything in frontEndUris is okay --- the frontend can import itself.
  // * Everything in kernel is okay --- the frontend is allowed to
  //   import package:kernel.
  // * For other entries, remove allowlisted entries.
  // * Everything else is an error.

  // Remove white-listed non-dart files.
  otherNonDartUris.remove(dotPackagesUri);
  otherNonDartUris.remove(repoDir.resolve("sdk/lib/libraries.json"));
  otherNonDartUris.remove(repoDir.resolve(".dart_tool/package_config.json"));

  // Remove white-listed dart files.
  for (String s in allowlistedExternalDartFiles) {
    otherDartUris.remove(repoDir.resolve(s));
  }

  if (otherNonDartUris.isNotEmpty || otherDartUris.isNotEmpty) {
    print("The following files was imported without being allowlisted:");
    for (Uri uri in otherNonDartUris) {
      print(" - $uri");
    }
    for (Uri uri in otherDartUris) {
      print(" - $uri");
    }
    exitCode = 1;
  }
}

CompilerOptions getOptions() {
  // Compile sdk because when this is run from a lint it uses the checked-in sdk
  // and we might not have a suitable compiled platform.dill file.
  Uri sdkRoot = computePlatformBinariesLocation(forceBuildDir: true);
  CompilerOptions options = new CompilerOptions()
    ..sdkRoot = sdkRoot
    ..compileSdk = true
    ..target = new VmTarget(new TargetFlags())
    ..librariesSpecificationUri = repoDir.resolve("sdk/lib/libraries.json")
    ..omitPlatform = true
    ..onDiagnostic = (DiagnosticMessage message) {
      if (message.severity == Severity.error) {
        Expect.fail(
            "Unexpected error: ${message.plainTextFormatted.join('\n')}");
      }
    }
    ..environmentDefines = const {};
  return options;
}
