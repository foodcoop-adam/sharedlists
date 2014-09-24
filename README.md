Sharedlists
===========
[![Dependency Status](https://gemnasium.com/foodcoop-adam/sharedlists.svg)](https://gemnasium.com/foodcoop-adam/sharedlists)
[![Issue board](http://b.repl.ca/v1/issue-board-78bdf2.png)](https://waffle.io/foodcoop-adam/foodsoft)
[![Documentation](http://b.repl.ca/v1/yard-docs-blue.png)](http://rubydoc.info/github/foodcoop-adam/sharedlists/frames)

Sharedlists is a simple rails driven database for managing multiple product lists of various suppliers.

This app is used in conjunction with [foodsoft](https://github.com/foodcoops/foodsoft). Some features
work specifically with the [foodcoop-adam](https://github.com/foodcoop-adam/foodsoft) fork, like the
orderdoc plugin and maximum quantity.

Import of spreadsheets (ods, sxc, xls, xlsx) is supported when OpenOffice.org
is installed (`libreoffice` in `PATH`).


Notes
-----

* Most relevant tests are the file import tests, run them using `rake test:units`.

* There is currently no user-interface for editing users.

* Mail synchronisation stores the spreadsheet and csv in `supplier_assets/mail_attachments`, while
  importing from the web-interface or using `rake` does _not_ store the spreadsheet. Foodsoft's
  orderdoc plugin requires the spreadsheet to be present (it's referenced from an article's `srcdata`).
