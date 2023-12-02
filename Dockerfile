FROM python:3.6-alpine

RUN pip install flask

COPY . /opt/

EXPOSE 8080

WORKDIR /opt

ARG IMAGE_TAG

ENV IMAGE_TAG=$IMAGE_TAG

ENTRYPOINT ["python", "app.py"]