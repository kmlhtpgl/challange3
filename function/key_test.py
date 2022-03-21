import json
import boto3

def lambda_handler(event, context):
    #1. Parse out query string param
    key = event['queryStringParameter']['key']
    print('key: ' + key)
    client = boto3.client('ssm')
    value = client.get_parameter(Name=key)
    parameter_value = json.loads(value['Parameter']['Value'])

    #2. Constract the body of response object
    keyRosponse = {}
    keyRosponse['key'] = key
    keyRosponse['value']= parameter_value 

    #3. Constuct the http response object

    responseObject = {}
    responseObject['statusCode'] : 200
    responseObject['headers'] = {}
    responseObject['headers']['Content-Type'] = 'application/json'
    responseObject['body'] = json.dumps(keyRosponse)

    #4. Return the response object

    return responseObject