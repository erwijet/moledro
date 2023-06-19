import os
import requests
import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
from operator import itemgetter
from fastapi import FastAPI
from bs4 import BeautifulSoup

app = FastAPI()

print(os.environ.get("FIREBASE_CRED"))

cred = credentials.Certificate(os.environ.get("FIREBASE_CRED"))
firebaseApp = firebase_admin.initialize_app(cred)

db = firestore.client()


@app.get("/")
async def index():
    return {"ok": True}


@app.get("/search/isbn")
async def search(q: str):
    # first, check to see if this query result already exists
    doc = db.collection("isbn_query_cache").document(q).get()

    if doc.exists:
        title, author, pub_date, binding, img = itemgetter("title", "author", "pub_date", "binding", "img")(doc.to_dict())

        return {
            "ok": True,
            "cached": True,
            "result": {
                "title": title,
                "author": author,
                "pub_date": pub_date,
                "binding": binding,
                "img": img,
            },
        }
    
    try:
        raw_html = requests.get(
            f"https://www.addall.com/New/NewSearch.cgi?query={q}&type=ISBN"
        ).text
        soup = BeautifulSoup(raw_html, "html.parser")
    
        title = soup.find("div", {"class": "ntitle"}).text
        author = soup.find("div", {"class": "nauthor"}).text.split("by")[1].strip()
    
        [pub_date, binding] = [
            " ".join(raw.split(":")[1:]).strip()
            for raw in soup.find("div", {"class": "ndesc"}).text.split("\n")[3:5]
        ]

        img = None

        if soup.find("div", { "class": "nimg" }):
            img = soup.find("div", {"class": "nimg"}).find("img")["src"]
    
            # if the image was sourced from amazon, attempt to upscale it
            if img.startswith("https://m.media-amazon.com/") and "160" in img:
                img = img.replace("160", "512")
    
        # write result to isbn_queries table

        doc_ref = db.collection("isbn_query_cache").document(q)

        doc_ref.set({
            "title": title,
            "author": author,
            "pub_date": pub_date,
            "binding": binding,
            "img": img,
        })
    
        return {
            "ok": True,
            "cached": False,
            "result": {
                "title": title,
                "author": author,
                "pub_date": pub_date,
                "binding": binding,
                "img": img,
            },
        }
    
    except Exception as err:
        return {
            "ok": False,
            "error": repr(err),
            "note": "you may have provided an invalid ISBN, or there may be an issue with the server",
        }
