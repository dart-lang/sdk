The `dart_app` depends on multiple packages with native assets.

`manifest.yaml` contains a list of all the files of the test projects.
This is used to copy the test projects to temporary folders when running tests,
to prevent tests accidentally using temporary files or interferring with each
other.
