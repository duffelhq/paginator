# Changelog

## v0.6.0 - 2018-11-20

### Changed

* Add support for Ecto 3. Remove support for Ecto 2.
([#40](https://github.com/duffelhq/paginator/pull/40), thanks! @van-mronov)

## v0.5.0 - 2018-10-31

### Added

* Expose the ability to generate cursors from records.
([#32](https://github.com/duffelhq/paginator/pull/32), thanks! @bernardd)

### Changed

* Config is now created and checked in Paginator.paginate/4, making it easier to
build your own pagination function in your Repo.

## v0.4.1 - 2018-10-23

### Fixed

* Fix argument error when trying to use `nil` cursors.
([#24](https://github.com/duffelhq/paginator/pull/24), thanks! @0nkery)

## v0.4.0 - 2018-07-11

### Fixed

* Fix potential DoS attack by using the `safe` option during decoding of cursors.
([#16](https://github.com/duffelhq/paginator/pull/16), thanks! @dbhobbs)

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
