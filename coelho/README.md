## Coelho

The ISBN search api, built on top of https://www.addall.com

## Getting Started

This service caches query results in a [supabase](https://www.supabase.com) table, so it requires a `SUPABASE_URL` and `SUPABASE_KEY` enviornment variable to be set.

```sh
$ git clone git@github.com:erwijet/moledro
$ cd coelho/

# install dependencies
$ poetry install

# run the server
$ SUPABASE_URL=<your_url> \
    SUPABASE_KEY=<your_key> \
    poetry run python3 -m uvicorn main:app
```

You can then run an ISBN serach by navigating to `http://localhost:8000/serach/isbn?q=<isbn>`
