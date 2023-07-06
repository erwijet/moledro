# Coelho

The `coelho` service aggregates and normalizes ISBN data across multiple providers.

## Getting Started

`coelho` reads and writes to a [firebase](https://firebase.google.com) store. Before starting, make sure you have a credientials file. Typically, this is called `firebase.json`. You can access this file from the Firebase Console by navigating to "Project Overview" -> "Project Settings" -> "Service Accounts" -> "Generate new Private Key".

Once you have this file, make sure to edit it and add the following field
```json
{
    // -- snip --

    "api_key": "<your_api_key>"
}
```

You can access this value by navigating to "Project Overview -> "Project Settings" -> "General" and copying the value under "Web API Key". For more information, please refer to [the firestore_db_and_auth crate docs](https://docs.rs/crate/firestore-db-and-auth/latest#:~:text=Document%20access%20via%20service%20account).


```bash
# cwd: <some_path>/moledro/coelho

$ docker build . -t moledro/coelho:latest
$ docker run -d -p "8000:8000" --env "FIREBASE_CRED=<path_to_firebase.json>" moledro/coleho:latest

$ curl localhost:8000/isbn/search?q=9780147511683 | jq
# {
#  "ok": true,
#  "cached": false,
#  "result": {
#    "title": " The Young Elites (A Young Elites Novel) ",
#    "author": "Lu, Marie",
#    "image": "http://images.ecampus.com/images/d/1/683/9780147511683.jpg",
#    "classification": {
#      "ddc": "813.6",
#      "fast_subjects": [
#        "Secret societies",
#        "Magic",
#        "Mutation (Biology)",
#        "Abused children",
#        "Dystopias",
#        "Kings and rulers--Succession",
#        "Ability",
#        "Adventure stories"
#      ]
#    }
#  }
# }
```

## ISBN Query Resolution

You can use `GET /isbn/search?q=<isbn>` to resolve ISBN queries.

### Response Shape

```ts
type CoelhoQueryResponse = 
    | { 
        ok: false, 
        when?: string, // what was attempted when the error occured 
        result: string  // the error debug string
    } | {  ok: true, cached: bool, result: IsbnResolution }

type IsbnResolution = {
    title: string,
    author: string,
    image?: string,
    classification?: { 
        ddc: string, // dewey decimal classification
        fast_subjects: string[] // https://www.oclc.org/en/fast.html
    }
}
```