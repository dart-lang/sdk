Simple Tests:
   test_simple.dart (main application)

   Works with templates:
      name_entry.tmpl      - simple template expression with attributes
      name_entry2.tmpl     - simple template expression inside nested tags
      name_entry_css.tmpl  - simple template expression with CSS

With Tests:
   test_with.dart (main application)

   Works with templates:
      productview.tmpl     - simplest with template
      productview2.tmpl    - with tested with var

List Tests:
   test_list.dart (main application)

   Works with templates:
      applications.tmpl     - simple list

Complex Tests:
   test_complex.dart (main application)

   Works with templates:
      top_searches.tmpl     - #each inside of a #with
      top_searches_css.tmpl - #each inside of a #with with CSS

Complex #2 Tests:
   test_complex2.dart (main application)

   Works with templates:
      top_searches2.tmpl     - #each inside of a #with w/ CSS and data model

Real World Application - Lists w/ events
   real_app.dart (main application)

   Works with templates:
      realviews.tmpl         - more complex app with event hookup (using var)

To build and run the above tests with frog in the browser.  Each .tmpl maps to
a test name:

  simple1        => name_entry.tmpl
  simple2        => name_entry2.tmpl
  simple3        => name_entry_css.tmpl
  with1          => productview.tmpl
  with2          => productview2.tmpl
  list           => applications.tmpl
  complex        => top_searches.tmpl
  complexcss     => top_searches_css.tmpl
  complex2       => top_searches2.tmpl
  real           => realviews.tmpl

  e.g. to run the Real World Application do:

      cd utils/test/templates
      ./run real
