FROM swift:5.3

ENV APP_HOME /app
WORKDIR $APP_HOME

COPY . .

WORKDIR /app

CMD ["swift", "build"]
