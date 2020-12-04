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
cat << EOF
Usage: $0 COMMAND ..."

Where COMMAND is one of:"

    noop - Just print description.
    clean - Remove out/ directory.
    linux-ia32-build - Build linux-ia32 for benchmarking.
    linux-ia32-archive - Archive linux-ia32.
    linux-ia32-benchmark - Try linux-ia32 benchmarking.
    linux-x64-build - Build linux-x64 for benchmarking.
    linux-x64-archive - Archive linux-x64.
    linux-x64-benchmark - Try linux-x64 benchmarking.
EOF
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
    rm -rf tmp
    rm -f linux-ia32.tar.gz
    rm -f linux-ia32_profile.tar.gz
    rm -f linux-x64.tar.gz
    rm -f linux-x64_profile.tar.gz
  elif [ "$command" = linux-ia32-build ]; then
    # NOTE: These are duplicated in tools/bots/test_matrix.json, keep in sync.
    ./tools/build.py --mode=release --arch=ia32 create_sdk runtime dart2js_platform.dill dart2js_nnbd_strong_platform.dill kernel-service.dart.snapshot
  elif [ "$command" = linux-ia32-archive ]; then
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
      -K '_ZN4dart9Bootstrap*_paths_E' out/ReleaseIA32/gen_snapshot
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
    tar -czf linux-ia32.tar.gz \
      --exclude .git \
      --exclude .gitignore \
      --exclude pkg/analysis_server/language_model \
      --exclude out/ReleaseIA32/dart-sdk/bin/model \
      --exclude pkg/front_end/testcases \
      -- \
      out/ReleaseIA32/dart2js_platform.dill \
      out/ReleaseIA32/vm_outline_strong.dill \
      out/ReleaseIA32/vm_platform_strong.dill \
      out/ReleaseIA32/gen/kernel_service.dill \
      out/ReleaseIA32/dart-sdk \
      out/ReleaseIA32/dart \
      out/ReleaseIA32/gen_snapshot \
      out/ReleaseIA32/dart2js_nnbd_strong_platform.dill \
      out/ReleaseIA32/kernel-service.dart.snapshot \
      out/ReleaseIA32/run_vm_tests \
      sdk \
      samples-dev/swarm \
      third_party/pkg \
      third_party/pkg_tested \
      .packages \
      .dart_tool/package_config.json \
      pkg \
      benchmarks \
      || (rm -f linux-ia32.tar.gz; exit 1)
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
    out/ReleaseIA32/dart --sound-null-safety --enable-experiment=non-nullable --profile-period=10000 --packages=.packages hello.dart
    out/ReleaseIA32/dart pkg/front_end/tool/perf.dart parse hello.dart
    out/ReleaseIA32/dart pkg/front_end/tool/perf.dart scan hello.dart
    out/ReleaseIA32/dart pkg/front_end/tool/fasta_perf.dart kernel_gen_e2e hello.dart
    out/ReleaseIA32/dart pkg/front_end/tool/fasta_perf.dart scan hello.dart
    out/ReleaseIA32/run_vm_tests --dfe=out/ReleaseIA32/kernel-service.dart.snapshot InitialRSS
    out/ReleaseIA32/run_vm_tests --dfe=out/ReleaseIA32/kernel-service.dart.snapshot --sound-null-safety --enable-experiment=non-nullable InitialRSS
    out/ReleaseIA32/run_vm_tests --dfe=out/ReleaseIA32/kernel-service.dart.snapshot KernelServiceCompileAll
    out/ReleaseIA32/run_vm_tests --dfe=out/ReleaseIA32/kernel-service.dart.snapshot --sound-null-safety --enable-experiment=non-nullable KernelServiceCompileAll
    out/ReleaseIA32/run_vm_tests --dfe=out/ReleaseIA32/kernel-service.dart.snapshot UseDartApi
    out/ReleaseIA32/run_vm_tests --dfe=out/ReleaseIA32/kernel-service.dart.snapshot --sound-null-safety --enable-experiment=non-nullable UseDartApi
    out/ReleaseIA32/dart --profile-period=10000 --packages=.packages benchmarks/Example/dart2/Example.dart
    out/ReleaseIA32/dart --sound-null-safety --enable-experiment=non-nullable --profile-period=10000 --packages=.packages benchmarks/Example/dart/Example.dart
    out/ReleaseIA32/dart benchmarks/FfiBoringssl/dart2/FfiBoringssl.dart
    out/ReleaseIA32/dart --sound-null-safety --enable-experiment=non-nullable benchmarks/FfiBoringssl/dart/FfiBoringssl.dart
    out/ReleaseIA32/dart benchmarks/FfiCall/dart2/FfiCall.dart
    out/ReleaseIA32/dart --sound-null-safety --enable-experiment=non-nullable benchmarks/FfiCall/dart/FfiCall.dart
    out/ReleaseIA32/dart benchmarks/FfiMemory/dart2/FfiMemory.dart
    out/ReleaseIA32/dart --sound-null-safety --enable-experiment=non-nullable benchmarks/FfiMemory/dart/FfiMemory.dart
    out/ReleaseIA32/dart benchmarks/FfiStruct/dart2/FfiStruct.dart
    out/ReleaseIA32/dart --sound-null-safety --enable-experiment=non-nullable benchmarks/FfiStruct/dart/FfiStruct.dart
    cd ..
    rm -rf tmp
  elif [ "$command" = linux-x64-build ]; then
    # NOTE: These are duplicated in tools/bots/test_matrix.json, keep in sync.
    ./tools/build.py --mode=release --arch=x64 create_sdk runtime gen_snapshot dart_precompiled_runtime dart2js_platform.dill dart2js_nnbd_strong_platform.dill kernel-service.dart.snapshot dartdevc_test
  elif [ "$command" = linux-x64-archive ]; then
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
      -K '_ZN4dart9Bootstrap*_paths_E' out/ReleaseX64/gen_snapshot
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
      -K '_ZN4dart9Bootstrap*_paths_E' out/ReleaseX64/dart_precompiled_runtime
    tar -czf linux-x64.tar.gz \
      --exclude .git \
      --exclude .gitignore \
      --exclude pkg/analysis_server/language_model \
      --exclude out/ReleaseX64/dart-sdk/bin/model \
      --exclude pkg/front_end/testcases \
      -- \
      out/ReleaseX64/dart2js_platform.dill \
      out/ReleaseX64/vm_outline_strong.dill \
      out/ReleaseX64/vm_platform_strong.dill \
      out/ReleaseX64/gen/kernel_service.dill \
      out/ReleaseX64/dart-sdk \
      out/ReleaseX64/dart \
      out/ReleaseX64/gen_snapshot \
      out/ReleaseX64/dart2js_nnbd_strong_platform.dill \
      out/ReleaseX64/kernel-service.dart.snapshot \
      out/ReleaseX64/run_vm_tests \
      third_party/d8/linux/x64 \
      third_party/firefox_jsshell/linux/ \
      out/ReleaseX64/dart_precompiled_runtime \
      out/ReleaseX64/gen/utils/dartdevc/kernel/ \
      out/ReleaseX64/ddc_outline.dill \
      out/ReleaseX64/gen/utils/dartdevc/sound/ \
      out/ReleaseX64/ddc_outline_sound.dill \
      sdk \
      samples-dev/swarm \
      third_party/pkg \
      third_party/pkg_tested \
      .packages \
      .dart_tool/package_config.json \
      pkg \
      benchmarks \
      || (rm -f linux-x64.tar.gz; exit 1)
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
    out/ReleaseX64/dart --sound-null-safety --enable-experiment=non-nullable --profile-period=10000 --packages=.packages hello.dart
    DART_CONFIGURATION=ReleaseX64 pkg/vm/tool/precompiler2 --packages=.packages hello.dart blob.bin
    DART_CONFIGURATION=ReleaseX64 pkg/vm/tool/dart_precompiled_runtime2 --profile-period=10000 blob.bin
    DART_CONFIGURATION=ReleaseX64 pkg/vm/tool/precompiler2 --sound-null-safety --enable-experiment=non-nullable --packages=.packages hello.dart blob.bin
    DART_CONFIGURATION=ReleaseX64 pkg/vm/tool/dart_precompiled_runtime2 --profile-period=10000 blob.bin
    out/ReleaseX64/dart --profile-period=10000 --packages=.packages --optimization-counter-threshold=-1 hello.dart
    out/ReleaseX64/dart-sdk/bin/dart2js --packages=.packages --out=out.js -m hello.dart
    third_party/d8/linux/x64/d8 --stack_size=1024 sdk/lib/_internal/js_runtime/lib/preambles/d8.js out.js
    out/ReleaseX64/dart-sdk/bin/dart2js --enable-experiment=non-nullable --sound-null-safety --packages=.packages --out=out.js -m hello.dart
    third_party/d8/linux/x64/d8 --stack_size=1024 sdk/lib/_internal/js_runtime/lib/preambles/d8.js out.js
    out/ReleaseX64/dart-sdk/bin/dart2js --packages=.packages --out=out.js -m hello.dart
    LD_LIBRARY_PATH=third_party/firefox_jsshell/linux/jsshell/ third_party/firefox_jsshell/linux/jsshell/js -f sdk/lib/_internal/js_runtime/lib/preambles/jsshell.js -f out.js
    out/ReleaseX64/dart-sdk/bin/dart2js --enable-experiment=non-nullable --sound-null-safety --packages=.packages --out=out.js -m hello.dart
    LD_LIBRARY_PATH=third_party/firefox_jsshell/linux/jsshell/ third_party/firefox_jsshell/linux/jsshell/js -f sdk/lib/_internal/js_runtime/lib/preambles/jsshell.js -f out.js
    out/ReleaseX64/dart-sdk/bin/dart2js --benchmarking-production --packages=.packages --out=out.js -m hello.dart
    third_party/d8/linux/x64/d8 --stack_size=1024 sdk/lib/_internal/js_runtime/lib/preambles/d8.js out.js
    out/ReleaseX64/dart-sdk/bin/dart2js --enable-experiment=non-nullable --sound-null-safety --benchmarking-production --packages=.packages --out=out.js -m hello.dart
    third_party/d8/linux/x64/d8 --stack_size=1024 sdk/lib/_internal/js_runtime/lib/preambles/d8.js out.js
    out/ReleaseX64/dart-sdk/bin/dart2js --benchmarking-x --packages=.packages --out=out.js -m hello.dart
    third_party/d8/linux/x64/d8 --stack_size=1024 sdk/lib/_internal/js_runtime/lib/preambles/d8.js out.js
    out/ReleaseX64/dart-sdk/bin/dart pkg/dev_compiler/tool/ddb -r d8 -b third_party/d8/linux/x64/d8 hello.dart
    out/ReleaseX64/dart-sdk/bin/dart pkg/dev_compiler/tool/ddb -r d8 -b third_party/d8/linux/x64/d8 --mode=compile --compile-vm-options=--print-metrics --packages=.packages --out out.js hello.dart
    out/ReleaseX64/dart-sdk/bin/dart pkg/dev_compiler/tool/ddb -r d8 -b third_party/d8/linux/x64/d8 --enable-experiment=non-nullable --sound-null-safety hello.dart
    out/ReleaseX64/dart-sdk/bin/dart pkg/dev_compiler/tool/ddb -r d8 -b third_party/d8/linux/x64/d8 --enable-experiment=non-nullable --sound-null-safety --mode=compile --compile-vm-options=--print-metrics --packages=.packages --out out.js hello.dart
    out/ReleaseX64/dart pkg/front_end/tool/perf.dart parse hello.dart
    out/ReleaseX64/dart pkg/front_end/tool/perf.dart scan hello.dart
    out/ReleaseX64/dart pkg/front_end/tool/fasta_perf.dart kernel_gen_e2e hello.dart
    out/ReleaseX64/dart pkg/front_end/tool/fasta_perf.dart scan hello.dart
    out/ReleaseX64/dart-sdk/bin/dart pkg/analysis_server/benchmark/benchmarks.dart run --quick --repeat 1 analysis-server-cold
    echo '[{"name":"foo","edits":[["pkg/compiler/lib/src/dart2js.dart","2016","2017"],["pkg/compiler/lib/src/options.dart","2016","2017"]]}]' > appjit_train_edits.json
    out/ReleaseX64/dart --background-compilation=false --snapshot-kind=app-jit --snapshot=pkg/front_end/tool/incremental_perf.dart.appjit pkg/front_end/tool/incremental_perf.dart --target=vm --sdk-summary=out/ReleaseX64/vm_platform_strong.dill --sdk-library-specification=sdk/lib/libraries.json pkg/compiler/lib/src/dart2js.dart appjit_train_edits.json
    out/ReleaseX64/dart --background-compilation=false pkg/front_end/tool/incremental_perf.dart.appjit --target=vm --sdk-summary=out/ReleaseX64/vm_platform_strong.dill --sdk-library-specification=sdk/lib/libraries.json pkg/front_end/benchmarks/ikg/hello.dart pkg/front_end/benchmarks/ikg/hello.edits.json
    out/ReleaseX64/dart --packages=.packages pkg/kernel/test/binary_bench.dart --golem AstFromBinaryLazy out/ReleaseX64/vm_platform_strong.dill
    out/ReleaseX64/run_vm_tests --dfe=out/ReleaseX64/kernel-service.dart.snapshot InitialRSS
    out/ReleaseX64/run_vm_tests --dfe=out/ReleaseX64/kernel-service.dart.snapshot --sound-null-safety --enable-experiment=non-nullable InitialRSS
    out/ReleaseX64/run_vm_tests --dfe=out/ReleaseX64/kernel-service.dart.snapshot KernelServiceCompileAll
    out/ReleaseX64/run_vm_tests --dfe=out/ReleaseX64/kernel-service.dart.snapshot --sound-null-safety --enable-experiment=non-nullable KernelServiceCompileAll
    out/ReleaseX64/run_vm_tests --dfe=out/ReleaseX64/kernel-service.dart.snapshot UseDartApi
    out/ReleaseX64/run_vm_tests --dfe=out/ReleaseX64/kernel-service.dart.snapshot --sound-null-safety --enable-experiment=non-nullable UseDartApi
    out/ReleaseX64/dart --profile-period=10000 --packages=.packages benchmarks/Example/dart2/Example.dart
    out/ReleaseX64/dart --sound-null-safety --enable-experiment=non-nullable --profile-period=10000 --packages=.packages benchmarks/Example/dart/Example.dart
    out/ReleaseX64/dart --profile-period=10000 --packages=.packages benchmarks/IsolateSpawn/dart2/IsolateSpawn.dart
    cd ..
    rm -rf tmp
  else
    echo "$0: Unknown command $command" >&2
    exit 1
  fi
done
