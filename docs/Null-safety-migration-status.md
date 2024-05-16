> [!IMPORTANT]
> This page was copied from https://github.com/dart-lang/sdk/wiki and needs review.
> Please [contribute](../CONTRIBUTING.md) changes to bring it up-to-date -
> removing this header - or send a CL to delete the file.

---

# Null safety migration

This page contains stats for the migration of packages on [pub.dev](https://pub.dev)
to Dart's [sound null safety](https://dart.dev/null-safety) feature.

The data below is based on the following criteria:

* Package supports null safety: The Dart SDK lower constraint is `>= 2.12.0-0`
* Package is unblocked for starting migrating to null safety: All direct dep of the package support null safety
* Blocking score: The number of packages (incl. transitive deps) only blocked from null-safety migration by this package. If a package is blocked by N dependencies, then it only contributes with a blocking score of 1/N.

_Note_: Pub.dev also has a list of
[packages with null safety](https://pub.dev/packages?unlisted=1&prerelease-null-safe=1).
This may show a slightly lower count than the "raw" counts below, as some
categories of packages (e.g. those
[marked discontinued](https://dart.dev/tools/pub/publishing#discontinue))
are not shown in the pub.dev search UI.

# Summary:

## Package counts (each package counts only once)
```
packages with null safety:                   8208

packages without null safety total:          13066
packages without null safety blocked:        2054
packages without null safety unblocked:      11012

packages in total (w. Dart 2.12 support):    21274
```




# Top blocking packages

Top 50 by blocking score (unblocked for migr.):
```
  shared_aws_api                            216.5   Yes
  angel_framework                            30.6   No
  angular                                    29.4   No
  galileo_framework                          21.2   No
  awareframework_core                        21.0   Yes
  mustache                                   18.0   Yes
  resource                                   16.7   Yes
  mango_ui                                   15.0   Yes
  dart2_constant                             14.5   Yes
  ocg_app                                    14.4   Yes
  jaguar_serializer                          13.3   Yes
  flushbar                                   11.2   Yes
  angel_container                            10.9   Yes
  flutter_facebook_login                     10.6   Yes
  transformer_page_view                      10.5   Yes
  toast                                      10.5   Yes
  nui_core                                   10.3   No
  validate                                   10.1   Yes
  intl_translation                           10.1   Yes
  mustache4dart                               9.4   Yes
  console_log_handler                         9.3   Yes
  masamune_flutter                            9.0   No
  streams_channel                             9.0   Yes
  latlong                                     8.9   No
  pip_services3_commons                       8.2   Yes
  database                                    8.0   Yes
  screen                                      8.0   Yes
  pip_services3_components                    7.7   No
  plugin_scaffold                             7.0   Yes
  class_extensions_annotations                6.3   Yes
  flutter_swiper                              6.2   No
  time_machine                                6.0   Yes
  merge_map                                   5.8   Yes
  react                                       5.8   Yes
  progress_dialog                             5.6   Yes
  code_buffer                                 5.6   Yes
  modal_progress_hud                          5.6   Yes
  jaguar_query                                5.3   Yes
  flutter_masked_text                         5.3   Yes
  utf                                         5.2   Yes
  kiilib_core                                 5.0   Yes
  pub_client                                  5.0   Yes
  flutter_icons                               5.0   Yes
  flutter_widgets                             4.9   Yes
  flutter_page_indicator                      4.8   Yes
  tinycolor                                   4.7   Yes
  pip_services3_rpc                           4.7   No
  tripledes                                   4.7   Yes
  galileo_orm                                 4.7   Yes
  body_parser                                 4.5   No
```
