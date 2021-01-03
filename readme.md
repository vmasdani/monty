# Monty

## (WIP)

A software for calculating monthly/annual subscription cost. Made in SQLite Rust (Actix + Diesel) and Elm.

.env file needed: 
```
APP_PORT=<your port, example 8085>
DATABASE_URL=<your database name>.sqlite3
FIXER_API_KEY=<your fixer api key>
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
2. Run
```
./release.py
```




