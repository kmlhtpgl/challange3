import json
from urllib import response
import boto3
import pprint

def lambda_handler(event, context):

    body = {"message": "You did not provide a valid Parameter Name"}

    client = boto3.client('ssm')
    try: 
        if event['httpMethod'] == "GET" and event["querystringParameters"]["ParameterName"]:
            resp = client.get_parameter(Name='key_test')
            body = resp["Parameter"]
    except Exception as e:
        body = {"message": "You did not provide a valid Parameter Name",
                "Error": str(e)} 
        pass

    
    
    response = {'statusCode': 200, 'body': json.dumps(body) }
    return response


import boto3
import json

client = boto3.client('ssm')

def lambda_handler(event, context):
    old_parameter = client.get_parameter(Name='/config/db')
    print(old_parameter)
    parameter_value = json.loads(old_parameter['Parameter']['Value'])
    parameter_value['my_version'] = '1.0'
    client.put_parameter(Name='/config/db', Overwrite=True, Value=json.dumps(parameter_value))