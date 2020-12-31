mkdir -p release/frontend &&\
cargo build --release &&\
cp -r target/release/monty .env release &&\
cd frontend &&\
./build.sh &&\
cp -r dist/* ../release/frontend
