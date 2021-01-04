The frontend_server package is used by both the flutter command line tool and the frontend_server_client package (used by webdev and package:test).

## API Stability

Changes to the command line API or behavior should be tested against the follwing test suites (in addition to normal HHH testing):
  * flutter_tools: https://github.com/flutter/flutter/tree/master/packages/flutter_tools
  * frontend_server_client: https://github.com/dart-lang/webdev/tree/master/frontend_server_client

Otherwise these changes will need to be carefully coordinated with the flutter tooling and frontend_server_client teams.

This API stability does not cover any of the source code APIs.


### Stable subset

* The frontend_server kernel compilation and expression evaluation for kernel should be considered "stable".
* The frontend_server JavaScript compilation is semi-stable, but clients should anticipate coordinated breaking changes in the future.
* The frontend_server JavaScript expression evaluation is experimental and is expected to change significantly from Dec 2020 through the end of 2021.
* Specific flags like the --flutter-widget-cache may be added for experimentation and should not be considered stable.
