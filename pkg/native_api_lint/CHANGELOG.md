## 0.1.0

- Initial release.
- Adds `api_not_available_on_min_target` lint rule (WARNING severity).
- Adds `api_obsoleted_on_min_target` lint rule (ERROR severity).
- Adds `api_deprecated_on_target` lint rule (INFO severity).
- Resolves deployment target from `ios/Podfile`, `ios/Runner.xcodeproj/project.pbxproj`,
  `macos/Podfile`, and `macos/Runner.xcodeproj/project.pbxproj`.
- Supports `analysis_options.yaml` override via `native_api_lint: { ios_min: '...' }`.
