import 'dart:convert';

Map<String, dynamic> buildOpenApiSpec({String host = 'localhost:8080'}) {
  return {
    'openapi': '3.0.0',
    'info': {
      'title': 'StaySpace Backend API',
      'version': '1.0.0',
      'description': 'OpenAPI spec for the StaySpace backend (auto-generated minimal spec)'
    },
    'servers': [
      {'url': 'http://$host'}
    ],
    'paths': {
      '/api/auth/register': {
        'post': {
          'summary': 'Register a new user',
          'requestBody': {
            'required': true,
            'content': {
              'application/json': {
                'schema': {'\$ref': '#/components/schemas/UserRegistration'}
              }
            }
          },
          'responses': {
            '200': {'description': 'User registered'}
          }
        }
      },
      '/api/auth/login': {
        'post': {
          'summary': 'Login',
          'requestBody': {
            'required': true,
            'content': {
              'application/json': {
                'schema': {'\$ref': '#/components/schemas/UserLogin'}
              }
            }
          },
          'responses': {
            '200': {'description': 'Authenticated'}
          }
        }
      },
      '/api/listings': {
        'get': {
          'summary': 'Get listings',
          'responses': {
            '200': {
              'description': 'A list of listings',
              'content': {
                'application/json': {
                  'schema': {'type': 'array', 'items': {'\$ref': '#/components/schemas/Listing'}}
                }
              }
            }
          }
        },
        'post': {
          'summary': 'Create a listing',
          'requestBody': {
            'required': true,
            'content': {
              'application/json': {
                'schema': {'\$ref': '#/components/schemas/ListingCreate'}
              }
            }
          },
          'responses': {'201': {'description': 'Created'}}
        }
      },
      '/api/listings/{id}': {
        'get': {
          'summary': 'Get listing by id',
          'parameters': [
            {
              'name': 'id',
              'in': 'path',
              'required': true,
              'schema': {'type': 'string'}
            }
          ],
          'responses': {'200': {'description': 'Listing object'}}
        }
      }
    },
    'components': {
      'schemas': {
        'UserRegistration': {
          'type': 'object',
          'properties': {
            'email': {'type': 'string'},
            'password': {'type': 'string'},
            'isLandlord': {'type': 'boolean'}
          }
        },
        'UserLogin': {
          'type': 'object',
          'properties': {'email': {'type': 'string'}, 'password': {'type': 'string'}}
        },
        'Listing': {
          'type': 'object',
          'properties': {
            'id': {'type': 'string'},
            'title': {'type': 'string'},
            'description': {'type': 'string'},
            'price': {'type': 'number'}
          }
        },
        'ListingCreate': {
          'type': 'object',
          'required': ['title', 'price'],
          'properties': {
            'title': {'type': 'string'},
            'description': {'type': 'string'},
            'price': {'type': 'number'}
          }
        }
      }
    }
  };
}

String openApiJson({String host = 'localhost:8080'}) => jsonEncode(buildOpenApiSpec(host: host));
