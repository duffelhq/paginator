# Changelog

## v0.4.1 - 2018-10-23

### Fixed

* Fix argument error when trying to use `nil` cursors. ([#24](https://github.com/duffelhq/paginator/pull/24), thanks! @0nkery)

## v0.4.0 - 2018-07-11

### Fixed

* Fix potential DoS attack by using the `safe` option during decoding of cursors. ([#16](https://github.com/duffelhq/paginator/pull/16), thanks! @dbhobbs)

## v0.3.1 - 2018-02-20

### Fixed

* Fix bug for queries with a pre-existing `where` clause. Sometimes, this clause
ended up being combined with the pagination filter using an `OR`.

## v0.3.0 - 2018-02-14

### Added

* `:limit` is now capped by `:maximum_limit`. By default, `:maximum_limit` is set
to 500.

## v0.2.0 - 2018-02-13

### Added

* `:total_count_limit` can be set to `:infinity` to return the accurate count of
records.

## v0.1.0 - 2018-02-13

Initial release! 🎉
