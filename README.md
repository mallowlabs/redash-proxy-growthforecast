# redash-proxy-growthforecast

A proxy lambda function to convert GrowthForecast JSON to Redash datasource.


## Requirements

* AWS CLI
* SAM CLI

## Deploy

```bash
$ aws s3 mb s3://your-sandbox --region ap-northeast-1
```

```bash
$ cd redash-proxy-growthforecast
$ bundle --path vendor/bundle --without test
```

```bash
$ sam package \
    --template-file template.yaml \
    --output-template-file serverless-output.yaml \
    --s3-bucket your-sandbox
```

```bash
$ sam deploy \
    --template-file serverless-output.yaml \
    --stack-name your-redash-proxy-growthforecast \
    --capabilities CAPABILITY_IAM \
    --parameter-overrides \
      GrowthForecastRoot=your-growth-forecast-root \
      GrowthForecastUsername=your-growth-forecast-username \
      GrowthForecastPassword=your-growth-forecast-password
```

Confirm your endpoint url.

```bash
$ aws cloudformation describe-stacks --stack-name your-redash-proxy-growthforecast --region ap-northeast-1
```

### Redash Side

Add `URL Data source`.

`Name`: Input friendly name.
`URL base path`: Input your endpoint url. ex: `https://your.execute-api.ap-northeast-1.amazonaws.com/Prod/proxy/`
`HTTP Basic Auth Username`: Input your GrwothForecast username (Basic Auth).
`HTTP Basic Auth Password`: Input your GrwothForecast password (Basic Auth).

Adde `Query`.

Input `{service_name}/{section_name}/{graph_name}`.
You can use query parameter. ex: `?t=y`.
