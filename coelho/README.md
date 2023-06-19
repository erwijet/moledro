## Coelho

The ISBN search api, built on top of https://www.addall.com

## Getting Started

This service caches query results in a [firebase](https://firebase.google.com/) collection, so it requires a `FIREBASE_CRED` enviornment variable to be set which points to your local firebase credention json file.

```sh
$ git clone git@github.com:erwijet/moledro
$ cd coelho/

# install dependencies
$ poetry install

# run the server
$ FIREBASE_CRED=<path/to/your/firebase-cred.json> \
    poetry run python3 -m uvicorn main:app
```

You can then run an ISBN serach by navigating to `http://localhost:8000/serach/isbn?q=<isbn>`
