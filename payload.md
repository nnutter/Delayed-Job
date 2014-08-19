Payload JSON Schema:

    {
        "$schema": "http://json-schema.org/draft-04/schema#",
        "title": "Delayed::Job Payload Schema",
        "description": "JSON Payload for Delayed::Job",
        "type": "object",
        "properties": {
            "package": {
                "description": "The package to use before calling the function",
                "type": "string"
            },
            "function": {
                "description": "The name of the function to call",
                "type": "string"
            },
            "args": {
                "description": "The arguments to pass to the function",
                "type": "array"
            }
        },
        "required": [ "package", "function", "args" ],
        "additionalProperties": false
    }

Example Payload:

    {
        "package": "Foo",
        "function": "Foo::bar",
        "args": [ 1.0, "foo" ]
    }

There are several [validators][] implementations as well as an
unofficial [web validator][].

  [validators]: http://json-schema.org/implementations.html
  [web validator]: http://json-schema-validator.herokuapp.com
