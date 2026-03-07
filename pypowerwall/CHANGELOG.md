# Changelog

## 0.1.1

- Fix: replaced Python entrypoint with POSIX shell script — upstream image does
  not have `python3` on `$PATH`

## 0.1.0

- Initial release
- Wraps `jasonacox/pypowerwall` as a Home Assistant add-on
- All configuration via the HA add-on UI
