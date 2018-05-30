FROM iron/ruby:2.2.4
WORKDIR /app
ADD . /app

ENTRYPOINT ["ruby", "quasi-autoscaler.rb"]
