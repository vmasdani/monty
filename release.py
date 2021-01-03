#!/usr/bin/env python3

import subprocess
import sys
import json

# Read release.json
release = open('release.json')
release_contents = json.loads(release.read())

release.close()

base_url = release_contents["base_url"]

index_html_contents = """<html>
  <head>
    <meta charset="UTF-8" />
    <title>Main</title>
    <script src="main.js"></script>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"> 
    <script src="https://apis.google.com/js/platform.js" async defer></script>
    <link
      href="https://cdn.jsdelivr.net/npm/bootstrap@5.0.0-beta1/dist/css/bootstrap.min.css"
      rel="stylesheet"
      integrity="sha384-giJF6kkoqNQ00vy+HMDP7azOuL0xtbfIcaT9wjKHr8RbDVddVHyTfAAsrekwKmP1"
      crossorigin="anonymous"
    />
    <script
      src="https://cdn.jsdelivr.net/npm/bootstrap@5.0.0-beta1/dist/js/bootstrap.bundle.min.js"
      integrity="sha384-ygbV9kiqUc6oa4msXn9868pTtWMgiQaeYH7/t7LECLbyPA2x65Kgf80OJFdroafW"
      crossorigin="anonymous"
    ></script>
    <meta
      name="google-signin-client_id"
      content="354857779698-4l5m51k5gcih8h5e2733s10hm504kk2u.apps.googleusercontent.com"
    />
  </head>

  <body>
    <div id="myapp"></div>
    <script>
      var app = Elm.Main.init({{
        node: document.getElementById("myapp"),
        flags: {{
          dateInt: new Date().getTime(),
          url: `{}`,
        }},
      }});
    </script>
    <script src="script.js"></script>
  </body>
</html>
""".format(base_url)

steps = [
    ("mkdir -p dist/frontend", "."),
    ("cargo build --release", "."),
    ("cp target/release/monty .env dist", "."),
    ("./build.sh", "./frontend"),
    ("cp dist/* ../dist/frontend", "./frontend"),
]

for (cmd, cwd) in steps:
    subprocess.run(cmd, shell=True, cwd=cwd)

f = open('./dist/frontend/index.html', 'w+')
f.write(index_html_contents)
f.close()

print("\nRelease success! files are located in ./dist")
