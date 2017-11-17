#!/bin/sh
# Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# This bot keeps benchmarks working. See messages below for details.

# If you need to change this script, you must also send a changelist to the
# benchmark system before submitting the change to this script. If you benchmark
# anything, you must test that basic benchmarking works in this file.

# Person responsible for maintaining this bot and available for questions.
owner=sortie

if [ $# -lt 1 ]; then
  echo "Usage: $0 COMMAND ..."
  echo
  echo "Where COMMAND is one of:"
  echo
  echo "    noop - Just print description."
  echo "    clean - Remove out/ directory."
  echo "    linux-ia32-build - Build linux-ia32 for benchmarking."
  echo "    linux-ia32-benchmark - Try linux-ia32 benchmarking."
  echo "    linux-x64-build - Build linux-x64 for benchmarking."
  echo "    linux-x64-benchmark - Try linux-x64 benchmarking."
  exit 1
fi

echo "This bot tests the interfaces the benchmark system expects to exist."
echo " "
echo "The command being run is: $0 $@"
echo " "
echo "Please reach out to $owner@ if you have any questions."
echo " "
echo "If this bot fails, you have made an incompatible change to the interfaces"
echo "expected by the benchmark system. Please, before landing your change,"
echo "first upload a changelist for review that updates the benchmark system"
echo "accordingly, then according to the approval of that changelist, update"
echo "update this bot to test the new interface the benchmark system expects."
echo "You are responsible for not breaking the benchmarks."
echo " "

on_shell_exit() {
  EXIT_CODE=$?
  set +x
  if [ $EXIT_CODE != 0 ]; then
    echo " "
    echo "This bot failed because benchmarks would fail. Please see the message"
    echo "near the top of this log. Please reach out to $owner@ if you have any"
    echo "questions about this bot."
  fi
}
trap on_shell_exit EXIT

PS4='# Exit: $?
################################################################################
# Command: '

set -e # Fail on error.
set -x # Debug which shell commands are run.

for command; do
  if [ "$command" = noop ]; then
    :
  elif [ "$command" = clean ]; then
    rm -rf out
    rm -f linux-ia32.tar.gz
    rm -f linux-ia32_profile.tar.gz
    rm -f linux-x64.tar.gz
    rm -f linux-x64_profile.tar.gz
  elif [ "$command" = linux-ia32-build ]; then
    ./tools/build.py --mode=release --arch=ia32 create_sdk
    ./tools/build.py --mode=release --arch=ia32 runtime
    tar -czf linux-ia32_profile.tar.gz \
      third_party/d8/linux/ia32/natives_blob.bin \
      third_party/d8/linux/ia32/snapshot_blob.bin \
      out/ReleaseIA32/vm_outline.dill \
      out/ReleaseIA32/vm_platform.dill \
      out/ReleaseIA32/vm_outline_strong.dill \
      out/ReleaseIA32/vm_platform_strong.dill \
      third_party/firefox_jsshell/linux/ \
      out/ReleaseIA32/dart-sdk \
      tools/dart2js/angular2_testing_deps \
      out/ReleaseIA32/dart \
      out/ReleaseIA32/dart_bootstrap \
      out/ReleaseIA32/run_vm_tests \
      third_party/d8/linux/ia32/d8 \
      sdk samples-dev/swarm \
      third_party/pkg \
      third_party/pkg_tested \
      .packages \
      pkg \
      runtime/bin \
      runtime/lib \
      --exclude .git \
      --exclude .gitignore || (rm -f linux-ia32_profile.tar.gz; exit 1)
    strip -w \
      -K 'kDartVmSnapshotData' \
      -K 'kDartVmSnapshotInstructions' \
      -K 'kDartCoreIsolateSnapshotData' \
      -K 'kDartCoreIsolateSnapshotInstructions' \
      -K '_ZN4dart3bin26observatory_assets_archiveE' \
      -K '_ZN4dart3bin30observatory_assets_archive_lenE' \
      -K '_ZN4dart3bin7Builtin22_builtin_source_paths_E' \
      -K '_ZN4dart3bin7Builtin*_paths_E' \
      -K '_ZN4dart3binL17vm_snapshot_data_E' \
      -K '_ZN4dart3binL24isolate_snapshot_buffer_E' \
      -K '_ZN4dart3binL27core_isolate_snapshot_data_E' \
      -K '_ZN4dart3binL27observatory_assets_archive_E' \
      -K '_ZN4dart3binL27vm_isolate_snapshot_buffer_E' \
      -K '_ZN4dart3binL29core_isolate_snapshot_buffer_E' \
      -K '_ZN4dart7Version14snapshot_hash_E' \
      -K '_ZN4dart7Version4str_E' \
      -K '_ZN4dart7Version7commit_E' \
      -K '_ZN4dart9Bootstrap*_paths_E' out/ReleaseIA32/dart
    strip -w \
      -K 'kDartVmSnapshotData' \
      -K 'kDartVmSnapshotInstructions' \
      -K 'kDartCoreIsolateSnapshotData' \
      -K 'kDartCoreIsolateSnapshotInstructions' \
      -K '_ZN4dart3bin26observatory_assets_archiveE' \
      -K '_ZN4dart3bin30observatory_assets_archive_lenE' \
      -K '_ZN4dart3bin7Builtin22_builtin_source_paths_E' \
      -K '_ZN4dart3bin7Builtin*_paths_E' \
      -K '_ZN4dart3binL17vm_snapshot_data_E' \
      -K '_ZN4dart3binL24isolate_snapshot_buffer_E' \
      -K '_ZN4dart3binL27core_isolate_snapshot_data_E' \
      -K '_ZN4dart3binL27observatory_assets_archive_E' \
      -K '_ZN4dart3binL27vm_isolate_snapshot_buffer_E' \
      -K '_ZN4dart3binL29core_isolate_snapshot_buffer_E' \
      -K '_ZN4dart7Version14snapshot_hash_E' \
      -K '_ZN4dart7Version4str_E' \
      -K '_ZN4dart7Version7commit_E' \
      -K '_ZN4dart9Bootstrap*_paths_E' out/ReleaseIA32/dart_bootstrap
    strip -w \
      -K 'kDartVmSnapshotData' \
      -K 'kDartVmSnapshotInstructions' \
      -K 'kDartCoreIsolateSnapshotData' \
      -K 'kDartCoreIsolateSnapshotInstructions' \
      -K '_ZN4dart3bin26observatory_assets_archiveE' \
      -K '_ZN4dart3bin30observatory_assets_archive_lenE' \
      -K '_ZN4dart3bin7Builtin22_builtin_source_paths_E' \
      -K '_ZN4dart3bin7Builtin*_paths_E' \
      -K '_ZN4dart3binL17vm_snapshot_data_E' \
      -K '_ZN4dart3binL24isolate_snapshot_buffer_E' \
      -K '_ZN4dart3binL27core_isolate_snapshot_data_E' \
      -K '_ZN4dart3binL27observatory_assets_archive_E' \
      -K '_ZN4dart3binL27vm_isolate_snapshot_buffer_E' \
      -K '_ZN4dart3binL29core_isolate_snapshot_buffer_E' \
      -K '_ZN4dart7Version14snapshot_hash_E' \
      -K '_ZN4dart7Version4str_E' \
      -K '_ZN4dart7Version7commit_E' \
      -K '_ZN4dart9Bootstrap*_paths_E' out/ReleaseIA32/run_vm_tests
    strip -w \
      -K 'kDartVmSnapshotData' \
      -K 'kDartVmSnapshotInstructions' \
      -K 'kDartCoreIsolateSnapshotData' \
      -K 'kDartCoreIsolateSnapshotInstructions' \
      -K '_ZN4dart3bin26observatory_assets_archiveE' \
      -K '_ZN4dart3bin30observatory_assets_archive_lenE' \
      -K '_ZN4dart3bin7Builtin22_builtin_source_paths_E' \
      -K '_ZN4dart3bin7Builtin*_paths_E' \
      -K '_ZN4dart3binL17vm_snapshot_data_E' \
      -K '_ZN4dart3binL24isolate_snapshot_buffer_E' \
      -K '_ZN4dart3binL27core_isolate_snapshot_data_E' \
      -K '_ZN4dart3binL27observatory_assets_archive_E' \
      -K '_ZN4dart3binL27vm_isolate_snapshot_buffer_E' \
      -K '_ZN4dart3binL29core_isolate_snapshot_buffer_E' \
      -K '_ZN4dart7Version14snapshot_hash_E' \
      -K '_ZN4dart7Version4str_E' \
      -K '_ZN4dart7Version7commit_E' \
      -K '_ZN4dart9Bootstrap*_paths_E' third_party/d8/linux/ia32/d8
    tar -czf linux-ia32.tar.gz \
      third_party/d8/linux/ia32/natives_blob.bin \
      third_party/d8/linux/ia32/snapshot_blob.bin \
      out/ReleaseIA32/vm_outline.dill \
      out/ReleaseIA32/vm_platform.dill \
      out/ReleaseIA32/vm_outline_strong.dill \
      out/ReleaseIA32/vm_platform_strong.dill \
      third_party/firefox_jsshell/linux/ \
      out/ReleaseIA32/dart-sdk \
      tools/dart2js/angular2_testing_deps \
      out/ReleaseIA32/dart \
      out/ReleaseIA32/dart_bootstrap \
      out/ReleaseIA32/run_vm_tests \
      third_party/d8/linux/ia32/d8 \
      sdk \
      samples-dev/swarm \
      third_party/pkg \
      third_party/pkg_tested \
      .packages \
      pkg \
      runtime/bin \
      runtime/lib \
      --exclude .git \
      --exclude .gitignore || (rm -f linux-ia32.tar.gz; exit 1)
  elif [ "$command" = linux-ia32-benchmark ]; then
    rm -rf tmp
    mkdir tmp
    cd tmp
    tar -xf ../linux-ia32.tar.gz
    cat > hello.dart << EOF
main() {
  print("Hello, World");
}
EOF
    out/ReleaseIA32/dart --profile-period=10000 --packages=.packages hello.dart
    out/ReleaseIA32/dart --profile-period=10000 --packages=.packages --checked hello.dart
    out/ReleaseIA32/dart-sdk/bin/dart2js --packages=.packages --out=out.js -m hello.dart
    third_party/d8/linux/ia32/d8 --stack_size=1024 sdk/lib/_internal/js_runtime/lib/preambles/d8.js out.js
    out/ReleaseIA32/dart-sdk/bin/dart2js --checked --packages=.packages --out=out.js -m hello.dart
    third_party/d8/linux/ia32/d8 --stack_size=1024 sdk/lib/_internal/js_runtime/lib/preambles/d8.js out.js
    out/ReleaseIA32/dart-sdk/bin/dart2js --packages=.packages --out=out.js -m hello.dart
    LD_LIBRARY_PATH=third_party/firefox_jsshell/linux/jsshell/ third_party/firefox_jsshell/linux/jsshell/js -f sdk/lib/_internal/js_runtime/lib/preambles/jsshell.js -f out.js
    out/ReleaseIA32/dart-sdk/bin/dart2js --trust-type-annotations --trust-primitives --fast-startup --packages=.packages --out=out.js -m hello.dart
    third_party/d8/linux/ia32/d8 --stack_size=1024 sdk/lib/_internal/js_runtime/lib/preambles/d8.js out.js
    out/ReleaseIA32/dart pkg/front_end/tool/perf.dart parse hello.dart
    out/ReleaseIA32/dart pkg/front_end/tool/perf.dart scan hello.dart
    out/ReleaseIA32/dart pkg/front_end/tool/fasta_perf.dart --legacy kernel_gen_e2e hello.dart
    out/ReleaseIA32/dart pkg/front_end/tool/fasta_perf.dart kernel_gen_e2e hello.dart
    out/ReleaseIA32/dart_bootstrap --parse_all --compiler_stats hello.dart
    out/ReleaseIA32/dart pkg/front_end/tool/perf.dart linked_summarize hello.dart
    out/ReleaseIA32/dart pkg/front_end/tool/perf.dart prelinked_summarize hello.dart
    out/ReleaseIA32/dart pkg/front_end/tool/fasta_perf.dart scan hello.dart
    out/ReleaseIA32/dart pkg/front_end/tool/perf.dart unlinked_summarize hello.dart
    out/ReleaseIA32/dart pkg/front_end/tool/perf.dart unlinked_summarize_from_sources hello.dart
    out/ReleaseIA32/dart --print_metrics pkg/analyzer_cli/bin/analyzer.dart --dart-sdk=sdk hello.dart
    cd ..
    rm -rf tmp
  elif [ "$command" = linux-x64-build ]; then
    ./tools/build.py --mode=release --arch=x64 create_sdk
    ./tools/build.py --mode=release --arch=x64 runtime
    ./tools/build.py --mode=release --arch=x64 dart_bootstrap
    ./tools/build.py --mode=release --arch=x64 dart_precompiled_runtime
    ./tools/build.py --mode=release --arch=simdbc64 runtime
    ./tools/build.py --mode=release --arch=x64 runtime_kernel
    tar -czf linux-x64_profile.tar.gz \
      third_party/d8/linux/x64/natives_blob.bin \
      third_party/d8/linux/x64/snapshot_blob.bin \
      out/ReleaseX64/vm_outline.dill \
      out/ReleaseX64/vm_platform.dill \
      out/ReleaseX64/vm_outline_strong.dill \
      out/ReleaseX64/vm_platform_strong.dill \
      out/ReleaseX64/dart-sdk \
      out/ReleaseSIMDBC64/dart \
      out/ReleaseX64/gen/kernel-service.dart.snapshot \
      out/ReleaseX64/dart \
      out/ReleaseX64/dart_bootstrap \
      out/ReleaseX64/run_vm_tests \
      third_party/d8/linux/x64/d8 \
      out/ReleaseX64/dart_precompiled_runtime \
      sdk \
      samples-dev/swarm \
      third_party/pkg \
      third_party/pkg_tested \
      .packages \
      pkg \
      runtime/bin \
      runtime/lib \
      --exclude .git \
      --exclude .gitignore || (rm -f linux-x64_profile.tar.gz; exit 1)
    strip -w \
      -K 'kDartVmSnapshotData' \
      -K 'kDartVmSnapshotInstructions' \
      -K 'kDartCoreIsolateSnapshotData' \
      -K 'kDartCoreIsolateSnapshotInstructions' \
      -K '_ZN4dart3bin26observatory_assets_archiveE' \
      -K '_ZN4dart3bin30observatory_assets_archive_lenE' \
      -K '_ZN4dart3bin7Builtin22_builtin_source_paths_E' \
      -K '_ZN4dart3bin7Builtin*_paths_E' \
      -K '_ZN4dart3binL17vm_snapshot_data_E' \
      -K '_ZN4dart3binL24isolate_snapshot_buffer_E' \
      -K '_ZN4dart3binL27core_isolate_snapshot_data_E' \
      -K '_ZN4dart3binL27observatory_assets_archive_E' \
      -K '_ZN4dart3binL27vm_isolate_snapshot_buffer_E' \
      -K '_ZN4dart3binL29core_isolate_snapshot_buffer_E' \
      -K '_ZN4dart7Version14snapshot_hash_E' \
      -K '_ZN4dart7Version4str_E' \
      -K '_ZN4dart7Version7commit_E' \
      -K '_ZN4dart9Bootstrap*_paths_E' out/ReleaseX64/dart
    strip -w \
      -K 'kDartVmSnapshotData' \
      -K 'kDartVmSnapshotInstructions' \
      -K 'kDartCoreIsolateSnapshotData' \
      -K 'kDartCoreIsolateSnapshotInstructions' \
      -K '_ZN4dart3bin26observatory_assets_archiveE' \
      -K '_ZN4dart3bin30observatory_assets_archive_lenE' \
      -K '_ZN4dart3bin7Builtin22_builtin_source_paths_E' \
      -K '_ZN4dart3bin7Builtin*_paths_E' \
      -K '_ZN4dart3binL17vm_snapshot_data_E' \
      -K '_ZN4dart3binL24isolate_snapshot_buffer_E' \
      -K '_ZN4dart3binL27core_isolate_snapshot_data_E' \
      -K '_ZN4dart3binL27observatory_assets_archive_E' \
      -K '_ZN4dart3binL27vm_isolate_snapshot_buffer_E' \
      -K '_ZN4dart3binL29core_isolate_snapshot_buffer_E' \
      -K '_ZN4dart7Version14snapshot_hash_E' \
      -K '_ZN4dart7Version4str_E' \
      -K '_ZN4dart7Version7commit_E' \
      -K '_ZN4dart9Bootstrap*_paths_E' out/ReleaseX64/dart_bootstrap
    strip -w \
      -K 'kDartVmSnapshotData' \
      -K 'kDartVmSnapshotInstructions' \
      -K 'kDartCoreIsolateSnapshotData' \
      -K 'kDartCoreIsolateSnapshotInstructions' \
      -K '_ZN4dart3bin26observatory_assets_archiveE' \
      -K '_ZN4dart3bin30observatory_assets_archive_lenE' \
      -K '_ZN4dart3bin7Builtin22_builtin_source_paths_E' \
      -K '_ZN4dart3bin7Builtin*_paths_E' \
      -K '_ZN4dart3binL17vm_snapshot_data_E' \
      -K '_ZN4dart3binL24isolate_snapshot_buffer_E' \
      -K '_ZN4dart3binL27core_isolate_snapshot_data_E' \
      -K '_ZN4dart3binL27observatory_assets_archive_E' \
      -K '_ZN4dart3binL27vm_isolate_snapshot_buffer_E' \
      -K '_ZN4dart3binL29core_isolate_snapshot_buffer_E' \
      -K '_ZN4dart7Version14snapshot_hash_E' \
      -K '_ZN4dart7Version4str_E' \
      -K '_ZN4dart7Version7commit_E' \
      -K '_ZN4dart9Bootstrap*_paths_E' out/ReleaseX64/run_vm_tests
    strip -w \
      -K 'kDartVmSnapshotData' \
      -K 'kDartVmSnapshotInstructions' \
      -K 'kDartCoreIsolateSnapshotData' \
      -K 'kDartCoreIsolateSnapshotInstructions' \
      -K '_ZN4dart3bin26observatory_assets_archiveE' \
      -K '_ZN4dart3bin30observatory_assets_archive_lenE' \
      -K '_ZN4dart3bin7Builtin22_builtin_source_paths_E' \
      -K '_ZN4dart3bin7Builtin*_paths_E' \
      -K '_ZN4dart3binL17vm_snapshot_data_E' \
      -K '_ZN4dart3binL24isolate_snapshot_buffer_E' \
      -K '_ZN4dart3binL27core_isolate_snapshot_data_E' \
      -K '_ZN4dart3binL27observatory_assets_archive_E' \
      -K '_ZN4dart3binL27vm_isolate_snapshot_buffer_E' \
      -K '_ZN4dart3binL29core_isolate_snapshot_buffer_E' \
      -K '_ZN4dart7Version14snapshot_hash_E' \
      -K '_ZN4dart7Version4str_E' \
      -K '_ZN4dart7Version7commit_E' \
      -K '_ZN4dart9Bootstrap*_paths_E' third_party/d8/linux/x64/d8
    strip -w \
      -K 'kDartVmSnapshotData' \
      -K 'kDartVmSnapshotInstructions' \
      -K 'kDartCoreIsolateSnapshotData' \
      -K 'kDartCoreIsolateSnapshotInstructions' \
      -K '_ZN4dart3bin26observatory_assets_archiveE' \
      -K '_ZN4dart3bin30observatory_assets_archive_lenE' \
      -K '_ZN4dart3bin7Builtin22_builtin_source_paths_E' \
      -K '_ZN4dart3bin7Builtin*_paths_E' \
      -K '_ZN4dart3binL17vm_snapshot_data_E' \
      -K '_ZN4dart3binL24isolate_snapshot_buffer_E' \
      -K '_ZN4dart3binL27core_isolate_snapshot_data_E' \
      -K '_ZN4dart3binL27observatory_assets_archive_E' \
      -K '_ZN4dart3binL27vm_isolate_snapshot_buffer_E' \
      -K '_ZN4dart3binL29core_isolate_snapshot_buffer_E' \
      -K '_ZN4dart7Version14snapshot_hash_E' \
      -K '_ZN4dart7Version4str_E' \
      -K '_ZN4dart7Version7commit_E' \
      -K '_ZN4dart9Bootstrap*_paths_E' out/ReleaseX64/dart_precompiled_runtime
    tar -czf linux-x64.tar.gz \
      third_party/d8/linux/x64/natives_blob.bin \
      third_party/d8/linux/x64/snapshot_blob.bin \
      out/ReleaseX64/vm_outline.dill \
      out/ReleaseX64/vm_platform.dill \
      out/ReleaseX64/vm_outline_strong.dill \
      out/ReleaseX64/vm_platform_strong.dill \
      out/ReleaseX64/dart-sdk \
      out/ReleaseSIMDBC64/dart \
      out/ReleaseX64/gen/kernel-service.dart.snapshot \
      out/ReleaseX64/dart \
      out/ReleaseX64/dart_bootstrap \
      out/ReleaseX64/run_vm_tests \
      third_party/d8/linux/x64/d8 \
      out/ReleaseX64/dart_precompiled_runtime \
      sdk \
      samples-dev/swarm \
      third_party/pkg \
      third_party/pkg_tested \
      .packages \
      pkg \
      runtime/bin \
      runtime/lib \
      --exclude .git \
      --exclude .gitignore  || (rm -f linux-x64.tar.gz; exit 1)
  elif [ "$command" = linux-x64-benchmark ]; then
    rm -rf tmp
    mkdir tmp
    cd tmp
    tar -xf ../linux-x64.tar.gz
    cat > hello.dart << EOF
main() {
  print("Hello, World");
}
EOF
    out/ReleaseX64/dart --profile-period=10000 --packages=.packages hello.dart
    out/ReleaseX64/dart --profile-period=10000 --packages=.packages --checked hello.dart
    out/ReleaseX64/dart --profile-period=10000 --packages=.packages --dfe=out/ReleaseX64/gen/kernel-service.dart.snapshot --kernel-binaries=out/ReleaseX64 hello.dart
    out/ReleaseX64/dart_bootstrap --packages=.packages --use-blobs --snapshot-kind=app-aot --snapshot=blob.bin hello.dart
    out/ReleaseX64/dart_precompiled_runtime --profile-period=10000 blob.bin
    DART_CONFIGURATION=ReleaseX64 pkg/vm/tool/dart2 --profile-period=10000 --packages=.packages hello.dart
    DART_CONFIGURATION=ReleaseX64 pkg/vm/tool/precompiler2 --packages=.packages hello.dart blob.bin
    DART_CONFIGURATION=ReleaseX64 pkg/vm/tool/dart_precompiled_runtime2 --profile-period=10000 blob.bin
    out/ReleaseSIMDBC64/dart --profile-period=10000 --packages=.packages hello.dart
    out/ReleaseSIMDBC64/dart --profile-period=10000 --checked --packages=.packages hello.dart
    out/ReleaseX64/dart pkg/front_end/tool/perf.dart parse hello.dart
    out/ReleaseX64/dart pkg/front_end/tool/perf.dart scan hello.dart
    out/ReleaseX64/dart pkg/front_end/tool/fasta_perf.dart --legacy kernel_gen_e2e hello.dart
    out/ReleaseX64/dart pkg/front_end/tool/fasta_perf.dart kernel_gen_e2e hello.dart
    out/ReleaseX64/dart_bootstrap --parse_all --compiler_stats hello.dart
    out/ReleaseX64/dart pkg/front_end/tool/perf.dart linked_summarize hello.dart
    out/ReleaseX64/dart pkg/front_end/tool/perf.dart prelinked_summarize hello.dart
    out/ReleaseX64/dart pkg/front_end/tool/fasta_perf.dart scan hello.dart
    out/ReleaseX64/dart pkg/front_end/tool/perf.dart unlinked_summarize hello.dart
    out/ReleaseX64/dart pkg/front_end/tool/perf.dart unlinked_summarize_from_sources hello.dart
    out/ReleaseX64/dart pkg/analysis_server/benchmark/benchmarks.dart run --quick --repeat 1 analysis-server-cold
    out/ReleaseX64/dart --print_metrics pkg/analyzer_cli/bin/analyzer.dart --dart-sdk=sdk hello.dart
    echo '[{"name":"foo","edits":[["pkg/compiler/lib/src/dart2js.dart","2016","2017"],["pkg/compiler/lib/src/options.dart","2016","2017"]]}]' > appjit_train_edits.json
    out/ReleaseX64/dart --background-compilation=false --snapshot-kind=app-jit --snapshot=pkg/front_end/tool/incremental_perf.dart.appjit pkg/front_end/tool/incremental_perf.dart --target=vm --sdk-summary=out/ReleaseX64/vm_platform.dill --sdk-library-specification=sdk/lib/libraries.json pkg/compiler/lib/src/dart2js.dart appjit_train_edits.json
    out/ReleaseX64/dart --background-compilation=false pkg/front_end/tool/incremental_perf.dart.appjit --target=vm --sdk-summary=out/ReleaseX64/vm_platform.dill --sdk-library-specification=sdk/lib/libraries.json pkg/front_end/benchmarks/ikg/hello.dart pkg/front_end/benchmarks/ikg/hello.edits.json
    out/ReleaseX64/dart --background-compilation=false pkg/front_end/tool/incremental_perf.dart.appjit --target=vm --mode=strong --implementation=driver --sdk-summary=out/ReleaseX64/vm_platform.dill --sdk-library-specification=sdk/lib/libraries.json pkg/front_end/benchmarks/ikg/hello.dart pkg/front_end/benchmarks/ikg/hello.edits.json
    out/ReleaseX64/dart --background-compilation=false pkg/front_end/tool/incremental_perf.dart.appjit --target=vm --mode=legacy --implementation=driver --sdk-summary=out/ReleaseX64/vm_platform.dill --sdk-library-specification=sdk/lib/libraries.json pkg/front_end/benchmarks/ikg/hello.dart pkg/front_end/benchmarks/ikg/hello.edits.json
    out/ReleaseX64/dart --background-compilation=false pkg/front_end/tool/incremental_perf.dart.appjit --target=vm --mode=strong --implementation=minimal --sdk-summary=out/ReleaseX64/vm_platform.dill --sdk-library-specification=sdk/lib/libraries.json pkg/front_end/benchmarks/ikg/hello.dart pkg/front_end/benchmarks/ikg/hello.edits.json
    out/ReleaseX64/dart --background-compilation=false pkg/front_end/tool/incremental_perf.dart.appjit --target=vm --mode=legacy --implementation=minimal --sdk-summary=out/ReleaseX64/vm_platform.dill --sdk-library-specification=sdk/lib/libraries.json pkg/front_end/benchmarks/ikg/hello.dart pkg/front_end/benchmarks/ikg/hello.edits.json
    cd ..
    rm -rf tmp
  else
    echo "$0: Unknown command $command" >&2
    exit 1
  fi
done
