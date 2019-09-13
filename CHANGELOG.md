# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.8] - 2019-08-30
### Enhancement
- Move over to the more verbose Rails style of defining data type for `parameter`. Use `:string`, `:float`, `:decimal`, `:boolean` and `:datetime` instead of old style of using `types.String`, `types.Float`, etc.

## [0.1.7] - 2019-08-27
### Enhancement
- Add automatic type detection for `GraphQL::Sugar::Object` to calculate the trivial classes.

## [0.1.6] - 2018-05-18
### Fixed
- Support for MySQL by conditionally checking PostgreSQL-specific `array?`

## [0.1.5] - 2018-02-13
### Fixed
- Add checks for `allow_blank` and `allow_nil` (#3)

## [0.1.4] - 2018-01-26
### Fixed
- Fix has_many through relationships (#2)

## [0.1.3] - 2017-12-12
### Fixed
- Fix has_one relationship (#1)

## [0.1.2] - 2017-11-07
### Added
- This CHANGELOG file

### Fixed
- Allow resolver type to be overridden correctly

## [0.1.1] - 2017-10-25
### Changed
- Improve README

## 0.1.0 - 2017-10-25
### Added
- First release of this gem

[Unreleased]: https://github.com/keepworks/graphql-sugar/compare/v0.1.6...HEAD
[0.1.6]: https://github.com/keepworks/graphql-sugar/compare/v0.1.5...v0.1.6
[0.1.5]: https://github.com/keepworks/graphql-sugar/compare/v0.1.4...v0.1.5
[0.1.4]: https://github.com/keepworks/graphql-sugar/compare/v0.1.3...v0.1.4
[0.1.3]: https://github.com/keepworks/graphql-sugar/compare/v0.1.2...v0.1.3
[0.1.2]: https://github.com/keepworks/graphql-sugar/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/keepworks/graphql-sugar/compare/v0.1.0...v0.1.1
