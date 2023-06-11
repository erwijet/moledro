import os
import requests
from operator import itemgetter
from fastapi import FastAPI
from supabase import create_client, Client
from bs4 import BeautifulSoup

app = FastAPI()

url: str = os.environ.get("SUPABASE_URL")
key: str = os.environ.get("SUPABASE_KEY")

supabase: Client = create_client(url, key)


@app.get("/")
async def index():
    return {"ok": True}


@app.get("/search/isbn")
async def search(q: str):
    # first, check to see if this query result already exists

    try:
        [title, author, pub_date, binding, img], *_ = map(
            itemgetter("title", "author", "pub_date", "binding", "img"),
            supabase.table("isbn_queries")
            .select("*")
            .eq("isbn_query", q)
            .execute()
            .data,
        )

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

    except ValueError:
        pass

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

        img = soup.find("div", {"class": "nimg"}).find("img")["src"]

        # if the image was sourced from amazon, attempt to upscale it
        if img.startswith("https://m.media-amazon.com/") and "160" in img:
            img = img.replace("160", "512")

        # write result to isbn_queries table

        supabase.table("isbn_queries").insert(
            {
                "isbn_query": q,
                "title": title,
                "author": author,
                "pub_date": pub_date,
                "binding": binding,
                "img": img,
            }
        ).execute()

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
