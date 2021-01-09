# Monty

A software for calculating monthly/annual subscription cost. Made in SQLite Rust (Actix + Diesel) and Elm.

.env file needed: 
```
DATABASE_URL=<your database name>.sqlite3
```

### Running (Backend): 
```
cargo run
``` 

### Running (Frontend):
```
cd frontend
./run.sh
```

### Release
1. Install [Node.JS](https://nodejs.org/en/download/) and `uglify-js` `(npm i -g uglify-js)`, Need Python 3 too.
2. Install [Docker](https://docs.docker.com/engine/install/) and [rust-musl-builder](https://github.com/emk/rust-musl-builder)
3. Add `env.json` with contents:
```
{
    "base_url": "http://localhost:8085",
    "fixer_api_key": "your-fixer-api-key",
    "server_port": "your_server_port",
}
```
4. Run
```
./release.py
```




