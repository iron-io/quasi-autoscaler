Building Docker image:
```
docker run --rm -v $PWD:/app -w /app iron/ruby:2.2.4-dev bundle install --standalone --clean
docker build -t yourusername/quasi-autoscaler:1 .
```

Testing locally:
```
docker run --rm -e 'token=mySecretToken' -e 'PAYLOAD_FILE=payload.json' yourusername/quasi-autoscaler:1
```

Deploying to Iron.io platform:
```
docker push yourusername/quasi-autoscaler:1
ironcli register -e 'token=mySecretToken' yourusername/quasi-autoscaler:1

```