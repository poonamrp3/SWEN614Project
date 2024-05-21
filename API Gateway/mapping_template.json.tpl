##  See http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-mapping-template-reference.html
#set($allParams = $input.params())
{
"method" : "$context.httpMethod", ## API method
"authcontext" : "$context.authorizer.stringkey", ## Optional output from Lambda Authorizers
## passthrough body
"body-json" : $input.json('$'),
## passthrough headers, querystrings and path parameters
"params" : {
#foreach($type in $allParams.keySet())
    #set($params = $allParams.get($type))
"$type" : {
    #foreach($paramName in $params.keySet())
    "$paramName" : "$util.escapeJavaScript($params.get($paramName))"
        #if($foreach.hasNext),#end
    #end
}
    #if($foreach.hasNext),#end
#end
}
}