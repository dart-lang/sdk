@echo off

@rem This is a wrapper that runs
@rem \\third_party\pkg\protobuf\protoc_plugin\bin\protoc-gen-dart using dart
@rem from \\tools\sdks\dart-sdk instead of from PATH.
set root_build_dir=%~dp0..\..\..\..
set PATH=%root_build_dir%\tools\sdks\dart-sdk\bin; && %root_build_dir%\third_party\pkg\protobuf\protoc_plugin\bin\protoc-gen-dart
