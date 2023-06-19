FROM docker.io/python:3.11-bullseye
WORKDIR /coelho


RUN pip3 install poetry
RUN poetry config virtualenvs.create false
RUN poetry install

COPY ./ /coelho

ENV FIREBASE_CRED firebase.json

CMD ["poetry", "run", "python3", "-m", "uvicorn", "main:app", "--host", "0.0.0.0"]
