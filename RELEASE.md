To release a new version of pyduckling:
1. git fetch upstream && git checkout upstream/master
2. git clean -xfdi
3. Update CHANGELOG.md with
   ```shell
   docker run -it --rm \
     -v "$(pwd)":/usr/local/src/your-app \
     githubchangeloggenerator/github-changelog-generator \
     -u phihos -p pyduckling --future-release <release version>
   ```
4. git add -A && git commit -m "Update Changelog"
5. Update release version in ``Cargo.toml`` (set release version, remove 'dev0')
6. Update the [version matrix](./README.md#version-matrix) in `README.md` by removing the `(unreleased)` behind the release version.
7. git add -A && git commit -m "Release vX.X.X"
8. git push upstream master
9. Make release on Github and use tag `v<release version>`
10. Wait for GitHub Actions to upload the wheels to PyPI
11. Update development version in ``Cargo.toml`` (add '-dev0' and increment minor, see [1](#explanation))
12. Update the [version matrix](./README.md#version-matrix) in `README.md` by adding `<future release version> (unreleased)`.
13. git add -A && git commit -m "Back to work"
14. git push upstream master


[<a name="explanation">1</a>] We need to append '-dev0', as Cargo does not support the '.dev0'
syntax.
