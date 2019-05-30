# Hello Uke

Find chords for stringed instruments.

Draw F major:

```
> log (draw ukulele 5 majorTriad)

G C E A
=======
| | ● |
+—+—+—+
● | | |
+—+—+—+
```

## Development

First time install:

```
npm install -g pulp bower purescript
bower install
pulp repl
pulp run

# To refresh deps
rm -rf bower_components/
rm -rf output/
bower install

pulp build --to docs/app.js
open docs/index.html
```
