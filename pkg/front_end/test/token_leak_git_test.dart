// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:developer" as developer;

import 'package:_fe_analyzer_shared/src/util/filenames.dart';
import 'package:front_end/src/api_prototype/file_system.dart' as api;
import 'package:front_end/src/base/uri_translator.dart';
import 'package:front_end/src/dill/dill_target.dart';
import 'package:front_end/src/kernel/kernel_target.dart';
import 'package:front_end/src/kernel/macro/macro.dart';
import 'package:kernel/ast.dart' show CanonicalName, Class;
import 'package:vm_service/vm_service.dart' as vmService;
import "package:vm_service/vm_service_io.dart" as vmServiceIo;

import 'compiler_test_helper.dart';
import 'find_all_subclasses_tool.dart';

Future<void> main(List<String> args) async {
  Set<Class> allTokenClasses = await getAllTokens();
  Map<String, List<Uri>> classesInUris = {};
  for (Class c in allTokenClasses) {
    (classesInUris[c.name] ??= []).add(c.fileUri);
  }

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
  vmService.VmService serviceClient =
      await vmServiceIo.vmServiceConnectUri(wsUriString);

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
            uriTranslator, bodyBuilderCreator, serviceClient, classesInUris);
      });

  await serviceClient.dispose();

  if (startedServiceProtocol) {
    await developer.Service.controlWebServer(
        enable: false, silenceOutput: true);
  }
}

class KernelTargetTester extends KernelTargetTest {
  final vmService.VmService serviceClient;
  final Map<String, List<Uri>> classesInUris;

  KernelTargetTester(
    api.FileSystem fileSystem,
    bool includeComments,
    DillTarget dillTarget,
    UriTranslator uriTranslator,
    BodyBuilderCreator bodyBuilderCreator,
    this.serviceClient,
    this.classesInUris,
  ) : super(fileSystem, includeComments, dillTarget, uriTranslator,
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

    throwOnLeaksOrNoFinds(
        await findAndPrintRetainingPaths(
            serviceClient, isolateId, classesInUris),
        "buildOutlines",
        classesInUris);
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

    throwOnLeaksOrNoFinds(
        await findAndPrintRetainingPaths(
            serviceClient, isolateId, classesInUris),
        "buildComponent",
        classesInUris);
    return buildResult;
  }
}

void throwOnLeaksOrNoFinds(Map<vmService.Class, int> foundInstances,
    String afterWhat, Map<String, List<Uri>> classesInUris) {
  Map<String, List<Uri>> notFound = {};
  for (MapEntry<String, List<Uri>> entry in classesInUris.entries) {
    notFound[entry.key] = new List.of(entry.value);
  }
  StringBuffer? sb;
  for (MapEntry<vmService.Class, int> entry in foundInstances.entries) {
    List<Uri> notFoundUrisForName = notFound[entry.key.name!]!;
    Uri uri = Uri.parse(entry.key.location!.script!.uri!);
    for (int i = 0; i < notFoundUrisForName.length; i++) {
      if (notFoundUrisForName[i].pathSegments.last == uri.pathSegments.last) {
        notFoundUrisForName.removeAt(i);
        break;
      }
    }
    if (entry.value > 0) {
      // 'SyntheticToken' will have 1 alive because of dummyToken in
      // front_end/lib/src/kernel/utils.dart. Hack around that.
      if (entry.key.name == "SyntheticToken" && entry.value == 1) {
        continue;
      }
      sb ??= new StringBuffer();
      sb.writeln('Found ${entry.value} instances of ${entry.key} '
          'after $afterWhat');
    }
  }
  if (sb != null) {
    throw sb.toString();
  }
  if (foundInstances.isEmpty) {
    throw "Didn't find anything.";
  }
  for (MapEntry<String, List<Uri>> notFoundData in notFound.entries) {
    if (notFoundData.value.isNotEmpty) {
      print("WARNING: Didn't find ${notFoundData.key}' in "
          "${notFoundData.value.join(" and ")}");
    }
  }
}

Future<Map<vmService.Class, int>> findAndPrintRetainingPaths(
    vmService.VmService serviceClient,
    String isolateId,
    Map<String, List<Uri>> classesInUrisFilter) async {
  vmService.AllocationProfile allocationProfile =
      await serviceClient.getAllocationProfile(isolateId, gc: true);

  Map<vmService.Class, int> foundInstances = {};

  for (vmService.ClassHeapStats member in allocationProfile.members!) {
    String? className = member.classRef!.name;
    if (className == null) continue;
    List<Uri>? uris = classesInUrisFilter[className];
    if (uris == null) continue;
    // File uris vs package uris --- for now just compare the filename.
    String? classUriString = member.classRef?.location?.script?.uri;
    if (classUriString == null) continue;
    Uri classUri = Uri.parse(classUriString);
    bool foundMatch = false;
    for (Uri uri in uris) {
      if (classUri.pathSegments.last == uri.pathSegments.last) {
        foundMatch = true;
        break;
      }
    }
    if (!foundMatch) continue;
    vmService.Class c = await serviceClient.getObject(
        isolateId, member.classRef!.id!) as vmService.Class;
    int? instancesCurrent = member.instancesCurrent;
    if (instancesCurrent == null) continue;
    foundInstances[c] = instancesCurrent;
    if (instancesCurrent == 0) continue;

    print("Found ${c.name} (location: ${c.location})");
    print("${member.classRef!.name}: "
        "(instancesCurrent: ${member.instancesCurrent})");
    print("");

    vmService.InstanceSet instances =
        await serviceClient.getInstances(isolateId, member.classRef!.id!, 100);
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
        print(retainingPath.gcRootType);
        String indent = ' ';
        for (int i = retainingPath.elements!.length - 1; i >= 0; i--) {
          vmService.RetainingObject retainingObject =
              retainingPath.elements![i];
          vmService.ObjRef? value = retainingObject.value;
          if (value is vmService.FieldRef) {
            print("${indent}field '${value.name}'");
          } else {
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
                className = 'class ${classRef.name}';
              }
            }
            print("${indent}${className}$field");
          }
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
