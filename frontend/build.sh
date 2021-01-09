# Ref from here: https://guide.elm-lang.org/optimization/asset_size.html

elm make --optimize src/Main.elm --output=main-unoptimised.js &&\
uglifyjs main-unoptimised.js --compress 'pure_funcs="F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9",pure_getters,keep_fargs=false,unsafe_comps,unsafe' | uglifyjs --mangle --output main.js &&\

echo "Compiled size:$(cat main-unoptimised.js | wc -c) bytes  (main-unoptimised.js)" &&\
echo "Minified size:$(cat main.js | wc -c) bytes  (main.js)" &&\
echo "Gzipped size: $(cat main.js | gzip -c | wc -c) bytes" &&\

rm -rf main-unoptimised.js &&\
mkdir -p dist &&\
cp index.html main.js script.js dist
