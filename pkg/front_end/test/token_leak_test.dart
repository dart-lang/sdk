// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:developer" as developer;

import 'package:front_end/src/api_prototype/file_system.dart' as api;
import 'package:_fe_analyzer_shared/src/util/filenames.dart';
import 'package:front_end/src/fasta/dill/dill_target.dart';
import 'package:front_end/src/fasta/kernel/kernel_target.dart';
import 'package:front_end/src/fasta/kernel/macro/macro.dart';
import 'package:front_end/src/fasta/uri_translator.dart';
import 'package:kernel/canonical_name.dart';
import 'package:vm_service/vm_service.dart' as vmService;
import "package:vm_service/vm_service_io.dart" as vmServiceIo;

import 'compiler_test_helper.dart';
import 'vm_service_helper.dart';

Future<void> main(List<String> args) async {
  args = args.toList();
  bool compileSdk = !args.remove('--no-sdk');
  developer.ServiceProtocolInfo serviceProtocolInfo =
      await developer.Service.getInfo();
  bool startedServiceProtocol = false;
  if (serviceProtocolInfo.serverUri == null) {
    startedServiceProtocol = true;
    serviceProtocolInfo = await developer.Service.controlWebServer(
        enable: true, silenceOutput: true);
  }

  Uri? serverUri = serviceProtocolInfo.serverUri;
  if (serverUri == null) {
    throw "Couldn't get service protocol url.";
  }
  String path = serverUri.path;
  if (!path.endsWith('/')) path += '/';
  String wsUriString = 'ws://${serverUri.authority}${path}ws';
  VmService serviceClient = await vmServiceIo.vmServiceConnectUri(wsUriString);

  await compile(
      inputs: args.isNotEmpty
          ? args.map(nativeToUri).toList()
          : [
              Uri.base
                  .resolve('pkg/front_end/test/token_leak_test_helper.dart'),
            ],
      compileSdk: compileSdk,
      kernelTargetCreator: (api.FileSystem fileSystem,
          bool includeComments,
          DillTarget dillTarget,
          UriTranslator uriTranslator,
          BodyBuilderCreator bodyBuilderCreator) {
        return new KernelTargetTester(fileSystem, includeComments, dillTarget,
            uriTranslator, bodyBuilderCreator, serviceClient);
      });

  await serviceClient.dispose();

  if (startedServiceProtocol) {
    await developer.Service.controlWebServer(
        enable: false, silenceOutput: true);
  }
}

class KernelTargetTester extends KernelTargetTest {
  final VmService serviceClient;

  // TODO(johnniwinther): Can we programmatically find all subclasses of [Token]
  //  instead?
  static const String className = 'StringTokenImpl';

  KernelTargetTester(
      api.FileSystem fileSystem,
      bool includeComments,
      DillTarget dillTarget,
      UriTranslator uriTranslator,
      BodyBuilderCreator bodyBuilderCreator,
      this.serviceClient)
      : super(fileSystem, includeComments, dillTarget, uriTranslator,
            bodyBuilderCreator);

  @override
  Future<BuildResult> buildOutlines({CanonicalName? nameRoot}) async {
    BuildResult buildResult = await super.buildOutlines(nameRoot: nameRoot);
    print('buildOutlines complete');
    vmService.VM vm = await serviceClient.getVM();
    if (vm.isolates!.length != 1) {
      throw "Expected 1 isolate, got ${vm.isolates!.length}";
    }
    vmService.IsolateRef isolateRef = vm.isolates!.single;

    String isolateId = isolateRef.id!;

    int foundInstances =
        await findAndPrintRetainingPaths(serviceClient, isolateId, className);
    if (foundInstances > 0) {
      throw 'Found $foundInstances instances of $className after '
          'buildOutlines';
    }
    return buildResult;
  }

  @override
  Future<BuildResult> buildComponent(
      {required MacroApplications? macroApplications,
      bool verify = false,
      bool allowVerificationErrorForTesting = false}) async {
    BuildResult buildResult = await super.buildComponent(
        macroApplications: macroApplications,
        verify: verify,
        allowVerificationErrorForTesting: allowVerificationErrorForTesting);
    print('buildComponent complete');
    vmService.VM vm = await serviceClient.getVM();
    if (vm.isolates!.length != 1) {
      throw "Expected 1 isolate, got ${vm.isolates!.length}";
    }
    vmService.IsolateRef isolateRef = vm.isolates!.single;

    String isolateId = isolateRef.id!;

    int foundInstances =
        await findAndPrintRetainingPaths(serviceClient, isolateId, className);
    if (foundInstances > 0) {
      throw 'Found $foundInstances instances of $className after '
          'buildComponent';
    }
    return buildResult;
  }
}

Future<int> findAndPrintRetainingPaths(
    vmService.VmService serviceClient, String isolateId, String filter) async {
  vmService.AllocationProfile allocationProfile =
      await serviceClient.getAllocationProfile(isolateId, gc: true);

  int foundInstances = 0;

  for (vmService.ClassHeapStats member in allocationProfile.members!) {
    if (member.classRef!.name != filter) continue;
    vmService.Class c = await serviceClient.getObject(
        isolateId, member.classRef!.id!) as vmService.Class;
    print("Found ${c.name} (location: ${c.location})");
    print("${member.classRef!.name}: "
        "(instancesCurrent: ${member.instancesCurrent})");
    print("");

    vmService.InstanceSet instances =
        await serviceClient.getInstances(isolateId, member.classRef!.id!, 100);
    foundInstances += instances.instances!.length;
    print(" => Got ${instances.instances!.length} instances");
    print("");

    for (vmService.ObjRef instance in instances.instances!) {
      try {
        vmService.Obj receivedObject =
            await serviceClient.getObject(isolateId, instance.id!);
        print("Instance: $receivedObject");
        vmService.RetainingPath retainingPath =
            await serviceClient.getRetainingPath(isolateId, instance.id!, 1000);

        print("Retaining path: (length ${retainingPath.length})");
        String indent = '';
        for (int i = retainingPath.elements!.length - 1; i >= 0; i--) {
          vmService.RetainingObject retainingObject =
              retainingPath.elements![i];
          vmService.ObjRef? value = retainingObject.value;
          String field;
          if (retainingObject.parentListIndex != null) {
            field = '[${retainingObject.parentListIndex}]';
          } else if (retainingObject.parentMapKey != null) {
            field = '[?]';
          } else if (retainingObject.parentField != null) {
            field = '.${retainingObject.parentField}';
          } else {
            field = '';
          }
          String className = '';
          if (value is vmService.InstanceRef) {
            vmService.ClassRef? classRef = value.classRef;
            if (classRef != null && classRef.name != null) {
              className = classRef.name!;
            }
          }
          print("${indent}${className}$field");
          indent += ' ';
        }

        print("");
      } catch (_) {
        // Suppress errors.
      }
    }
  }

  print("Done!");

  return foundInstances;
}
