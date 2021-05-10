# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v1.0.4 - 2021-03-15

* Fix type errors, thanks! @djthread:
  * ([#96](https://github.com/duffelhq/paginator/pull/96))
  * ([#98](https://github.com/duffelhq/paginator/pull/98))
* Fix tuples typo in documentation: ([#99](https://github.com/duffelhq/paginator/pull/99), thanks! @iamsekun)
* Use GitHub Actions for continuous integration: ([#100](https://github.com/duffelhq/paginator/pull/100), thanks! @dolfinus)
* Update package dependencies
  * `calendar` -> 1.0.0
  * `ecto` -> 3.0.9
  * `ex_machina` -> 2.7.0
  * `plug_crypto` -> 1.2.1
  * `postgrex` -> 0.14.3

## v1.0.3 - 2020-12-18

* Fix cursor field validation bug ([#93](https://github.com/duffelhq/paginator/pull/93))

## v1.0.2 - 2020-11-20

* Update package dependencies
  * `inch` -> 2.0
  * `plug_crypto` -> 1.2.0
  * `ex_doc` -> 0.23.0

## v1.0.1 - 2020-08-18

* Fix sorting bug in cursor query ([#73](https://github.com/duffelhq/paginator/pull/73))

## v1.0.0 - 2020-08-17

* Fix Remote Code Execution Vulnerability ([#69](https://github.com/duffelhq/paginator/pull/69) - Thank you @p-!)
* Fix cursor mismatch bug ([#68]((https://github.com/duffelhq/paginator/pull/68))

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
