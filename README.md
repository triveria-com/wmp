# Wallet Messaging Protocol
## Introduction
Wallet Messaging Protocol (WMP) is a websocket-based communication protocol which provides secure trusted channels where two wallets can exchange data such as OpenID4VCI credential offers or credential verification requests.  
It does not aim to replace these specifications, only to provide an additional layer through which wallets can exchange information.

## Architecture
### Basic concepts

- Entity: Actor in WMP
- Entity Type: Entity can be either a `server` -- websocket server or `client` -- websocket client
- Wallet Type: string with value `issuer` -- entity issuing verifiable credentials, `verifier` -- entity verifying verifiable credentials, `holder` -- entity holding verifiable credentials
- Invitation: Public document describing how a client entity may connect to a server entity through WMP
- WMP Channel: a websocket connection between two entities
- Key Identifier: Object identifying a public key, e.g. DID, X509 Certificate etc.
- ID Token: Document describing the entity, it's wallet keys and their identifiers

New connections between entities are established using a so-called invitation flow:
```mermaid
sequenceDiagram
Server ->> Server: Publishes invitation JWT<br/>With code_challenge
Client -->> Server: GET: invitation endpoint
Client ->> Server: Connects to WMP channel
activate Server
Server ->> Client: Verification request <br/>With code_verifier
Client -->> Client: Verifies code_challenge
Client ->> Server: Sends verification response
Server -->> Server: Verifies verification <br/>response
Server ->> Client: Sends ID Token
Client ->> Server: Sends ID Token

Client -->> Client: Verifies server ID Token

Server -->> Server: Verifies client ID Token
Note over Server,Client: Trusted connection channel has been<br/> established
```
Connections between trusted entities are established by the following flow:
```mermaid
sequenceDiagram
participant Server
participant Client
Client ->> Server: Connects to WMP channel
activate Server
Server ->> Client: Sends verification request
Client ->> Server: Sends verification response
Server -->> Server: Verifies verification <br/>response
Note over Server,Client: Trusted connection channel has been<br/> established
```
## Message structure
All messages in WMP are Json Web Tokens (JWTs) that are signed by the corresponding entity.
The following JWT header claims shall be present in every message:
- `typ`: Specifies the type of WMP message, e.g. `jwt+wmp/verification_request`
- `jwk`: Public key that is used to verify the JWT signature validity. For now, other methods of specifying the key (such as using `kid` or `x5c` claim) are not supported

The following JWT payload claims shall be present in every message:
- `iss`: Identifier of the message issuer. In cases where the entity has a public URL, it shall be used. Otherwise, the `https://self-issued.me` identifier shall be used.

Specific message types define additional JWT payload claims.

## Invitation
WMP invitation is a JWT signed by a WMP server entity which is then published.
A WMP invitation has the following JWT header claims:
- `typ`: `jwt+wmp/invitation`

And the following JWT Payload claims:
- `channel_url`: A websocket url of the WMP connection
- `code_challenge`: a PKCE code challenge that will be used by the client to validate the invitation
- `code_challenge`: a PKCE code challenge method. Only the value of `S256` is supported.
- `exp`: The invitation expiration. It is recommended to be no longer than 24 hours.

Here is an example of a WMP invitation:
```
eyJhbGciOiJFUzI1NiIsImp3ayI6eyJjcnYiOiJQLTI1NiIsImt0eSI6IkVDIiwieCI6IlpDeEF5bGRXVDdiTHpZQjlQaXVTdTBTRGJLdFZZdnQtY3FnbmVvaDR2dnciLCJ5IjoiRmd6bkFkNzZ2NDl4OEhnU1Q3NmdMcVBSV3JSU0tQYTA3ZDBkUUFxZG9HNCJ9LCJ0eXAiOiJqd3Qrd21wL2ludml0YXRpb24ifQ.eyJjaGFubmVsX3VybCI6IndzOi8vbG9jYWxob3N0OjEyMzQvYXBpL3YxL3dtcC9jaGFubmVsLzRlMDU4M2ZlLTVhZTAtNDYyMy04MzI4LTM3YTYxNDNiMzZkZC8wMTk5ZjkxNi1mNDA3LTcyNWYtOWQwMC0wM2FiYTA3ZTlmMDEiLCJjb2RlX2NoYWxsZW5nZSI6ImVzdTZlMm9DU1Ayd2VGRTVsUXlTdG5VV0JZOTd3MVgyeXRSYm4yYlBIYjAiLCJjb2RlX2NoYWxsZW5nZV9tZXRob2QiOiJTMjU2IiwiZXhwIjoxNzYwOTA3MDU1LCJpYXQiOjE3NjA4MjA2NTUsImlzcyI6IndzOi8vbG9jYWxob3N0OjEyMzQvYXBpL3YxL3dtcC80ZTA1ODNmZS01YWUwLTQ2MjMtODMyOC0zN2E2MTQzYjM2ZGQifQ.jhesEZ4Ym5u5fVdV2f8hxECXuMI-4RE8uIfpU--xRw2lcwirCF0ZHL9qq8JK-hSZ_YOoJEe2E7JWZsduWvWFIA
```
Here is the decoded token header:
```
{
  "alg": "ES256",
  "jwk": {
    "crv": "P-256",
    "kty": "EC",
    "x": "ZCxAyldWT7bLzYB9PiuSu0SDbKtVYvt-cqgneoh4vvw",
    "y": "FgznAd76v49x8HgST76gLqPRWrRSKPa07d0dQAqdoG4"
  },
  "typ": "jwt+wmp/invitation"
}
```
Here is the decoded token payload:
```
{
  "channel_url": "ws://localhost:1234/api/v1/wmp/channel/4e0583fe-5ae0-4623-8328-37a6143b36dd/0199f916-f407-725f-9d00-03aba07e9f01",
  "code_challenge": "esu6e2oCSP2weFE5lQyStnUWBY97w1X2ytRbn2bPHb0",
  "code_challenge_method": "S256",
  "exp": 1760907055,
  "iat": 1760820655,
  "iss": "ws://localhost:1234/api/v1/wmp/4e0583fe-5ae0-4623-8328-37a6143b36dd"
}
```
The invitation shall be published by a Server to an endpoint where it can be retrieved by a Client with an HTTP GET request. This URL can be delivered to the client by other channels such as QR code, email, [Pigeons](https://www.rfc-editor.org/rfc/rfc1149), etc.

## WMP Messages
In addition to the specified message types, more can be added to extend the functionality of WMP.
### Verification Request
Verification request is sent by the WMP Server Entity to the Client Entity. It's header `typ` claim shall be set to `jwt+wmp/verification_request`.
The payload shall contain the following claims:
- `nonce`: A random string that the client has to include in a verification response. A source of randomness with high entropy is recommended.
- `code_verifier`: Code verifier to the PKCE Code challenge present in the invitation. Present only during the invitation flow.

Here is an example of a WMP Verification Request:
```
eyJhbGciOiJFUzI1NiIsImp3ayI6eyJjcnYiOiJQLTI1NiIsImt0eSI6IkVDIiwieCI6IlpDeEF5bGRXVDdiTHpZQjlQaXVTdTBTRGJLdFZZdnQtY3FnbmVvaDR2dnciLCJ5IjoiRmd6bkFkNzZ2NDl4OEhnU1Q3NmdMcVBSV3JSU0tQYTA3ZDBkUUFxZG9HNCJ9LCJ0eXAiOiJqd3Qrd21wL3ZlcmlmaWNhdGlvbl9yZXF1ZXN0In0.eyJjb2RlX3ZlcmlmaWVyIjoiTXl5SjRmTUNvT1pEMGMxNTJwdy1KSzFkN3I5aTZsTG9xbnpsS0NwZXNsbyIsImV4cCI6MTc2MDgyMDk2OCwiaWF0IjoxNzYwODIwNjY4LCJpc3MiOiJodHRwOi8vbG9jYWxob3N0OjEyMzQvYXBpL3YxL3dtcC80ZTA1ODNmZS01YWUwLTQ2MjMtODMyOC0zN2E2MTQzYjM2ZGQiLCJub25jZSI6IjZHajZVLW1QSnlXU2hnbENfb3V3ZEd3SUhJQjhySk1sek5QYmVXSnp4MUEifQ.58pZe7b5QQYRkB111UcFwxHaGR3k8pZ8TiFShfLYFfj-ZAx8cSFYEDQjwo9yrE2aFRx0x6hbo7WgLHGyNkNvug
```
Here is the decoded token header:
```
{
  "alg": "ES256",
  "jwk": {
    "crv": "P-256",
    "kty": "EC",
    "x": "ZCxAyldWT7bLzYB9PiuSu0SDbKtVYvt-cqgneoh4vvw",
    "y": "FgznAd76v49x8HgST76gLqPRWrRSKPa07d0dQAqdoG4"
  },
  "typ": "jwt+wmp/verification_request"
}
```
Here is the decoded token payload:
```
{
  "code_verifier": "MyyJ4fMCoOZD0c152pw-JK1d7r9i6lLoqnzlKCpeslo",
  "exp": 1760820968,
  "iat": 1760820668,
  "iss": "http://localhost:1234/api/v1/wmp/4e0583fe-5ae0-4623-8328-37a6143b36dd",
  "nonce": "6Gj6U-mPJyWShglC_ouwdGwIHIB8rJMlzNPbeWJzx1A"
}
```

### Verification response
Verification response is sent by the WMP Client Entity to the Server Entity. It's header `typ` claim shall be set to `jwt+wmp/verification_response`.
The payload shall contain the following claims:
- `nonce`: Nonce value that was provided by the Server Entity during verification request.

Here is an example verification response:
```
eyJhbGciOiJFUzI1NiIsImp3ayI6eyJjcnYiOiJQLTI1NiIsImt0eSI6IkVDIiwieCI6IlpDeEF5bGRXVDdiTHpZQjlQaXVTdTBTRGJLdFZZdnQtY3FnbmVvaDR2dnciLCJ5IjoiRmd6bkFkNzZ2NDl4OEhnU1Q3NmdMcVBSV3JSU0tQYTA3ZDBkUUFxZG9HNCJ9LCJ0eXAiOiJqd3Qrd21wL3ZlcmlmaWNhdGlvbl9yZXNwb25zZSJ9.eyJpYXQiOjE3NjA4MjA2NzksImlzcyI6Imh0dHA6Ly9sb2NhbGhvc3Q6NTY3OC9hcGkvdjEvd21wLzRlMDU4M2ZlLTVhZTAtNDYyMy04MzI4LTM3YTYxNDNiMzZkZCIsIm5vbmNlIjoiNkdqNlUtbVBKeVdTaGdsQ19vdXdkR3dJSElCOHJKTWx6TlBiZVdKengxQSJ9.pnT5cOEypNeC-5aewxB6lif_jK7vWQ92tix5ASerGLwEbioUB84iVdCRB9P951HTFBKaJrTxLtfD4JUze9zSeg
```
Here is the decoded token header:
```
{
  "alg": "ES256",
  "jwk": {
    "crv": "P-256",
    "kty": "EC",
    "x": "ZCxAyldWT7bLzYB9PiuSu0SDbKtVYvt-cqgneoh4vvw",
    "y": "FgznAd76v49x8HgST76gLqPRWrRSKPa07d0dQAqdoG4"
  },
  "typ": "jwt+wmp/verification_response"
}
```
Here is the decoded token payload:
```
{
  "iat": 1760820679,
  "iss": "http://localhost:5678/api/v1/wmp/4e0583fe-5ae0-4623-8328-37a6143b36dd",
  "nonce": "6Gj6U-mPJyWShglC_ouwdGwIHIB8rJMlzNPbeWJzx1A"
}
```

### ID Token
ID token is sent by both client and server entities. It's header `typ` claim shall be set to `jwt+wmp/id_token`.
The payload shall contain the following claims:
- `entity_types`: Array of wallet types
- `identifiers`: Array of wallet key identifiers
- `issuer_url`: OIDC Issuer endpoint of the entity wallet. Present only if `entity_types` contains `issuer`
- `authorization_url`: OIDC Authorization endpoint of the entity wallet. Present only if `entity_types` contains `issuer` or `verifier`
- `name`: OPTIONAL A human readable identifier of the entity

**Wallet key identifier:**
A wallet key identifier object is a JSON object containing the following claims:
- `type`: Type of the wallet key identifier. Currently supported types are `did` for DIDs and `x509` for X509 certificate chains
- `identifier`: String array. When `type` is set to `x509`, it's elements are base64 encoded X509 certificate chain elements with its leaf being the first element. When `type` is set to `did`, the array has only one element -- the DID
- `proof`: A sample JWT token signed with a private key corresponding to the public key that the key identifier points to. The JWT shall have it's header `typ` claim set to `jwt+wmp/entity-id-proof`.

Here is an example ID Token:
```
eyJhbGciOiJFUzI1NiIsImp3ayI6eyJjcnYiOiJQLTI1NiIsImt0eSI6IkVDIiwieCI6IjBPRnRxUUw3bmxxZl9zVHBxNTY1TlFEUm1sTVhVT1lQRnBQZ3p5MDFVaVkiLCJ5IjoiTGtmbTJ3T0I4THpweWlkb3B3ZG96ck9yWTRUejNxZU84bkZVYUcxSm4wQSJ9LCJ0eXAiOiJqd3Qrd21wL2lkX3Rva2VuIn0.eyJhdXRob3JpemF0aW9uX3VybCI6Imh0dHA6Ly9sb2NhbGhvc3Q6NTY3OC9hcGkvdjEvYXV0aC9lOTYxNGM2NS0zNDY4LTQwMDUtYmVhMi00MjJiOGNjNDZhMzciLCJlbnRpdHlfdHlwZXMiOlsiaG9sZGVyIiwiaXNzdWVyIl0sImlhdCI6MTc2MDgyMDE4MCwiaWRlbnRpZmllcnMiOlt7ImlkZW50aWZpZXIiOlsiZGlkOmtleTp6MmRtekQ4MWNnUHg4VmtpN0pidXVNbUZZcldQZ1lveXR5a1VaM2V5cWh0MWo5S2JuUFVRRFJuQzFubVdxbWRIVTc0VXpEUTYxUTR6Z3lEZzlWeGE4amR4d1RVWERDQ2pZN2k3bUNGUkR3MnRGYjIyRTluMXlxRm5ya2RGWGVETnY1S2U4b1BGTVU5S3kySlVmdE1QR1M3S0RaZjRDWUx6M3Y1WjNrSlNtcXo5UzFwMXY0Il0sInByb29mIjoiZXlKaGJHY2lPaUpGVXpJMU5pSXNJbXAzYXlJNmV5SmpjbllpT2lKUUxUSTFOaUlzSW10MGVTSTZJa1ZESWl3aWVDSTZJakJQUm5SeFVVdzNibXh4Wmw5elZIQnhOVFkxVGxGRVVtMXNUVmhWVDFsUVJuQlFaM3A1TURGVmFWa2lMQ0o1SWpvaVRHdG1iVEozVDBJNFRIcHdlV2xrYjNCM1pHOTZjazl5V1RSVWVqTnhaVTg0YmtaVllVY3hTbTR3UVNKOUxDSjBlWEFpT2lKcWQzUXJkMjF3TDJWdWRHbDBlUzFwWkMxd2NtOXZaaUo5LmV5SnBZWFFpT2pFM05qQTRNakF4T0RBc0ltbHpjeUk2SW5kek9pOHZhSFIwY0RvdkwyeHZZMkZzYUc5emREbzFOamM0TDJGd2FTOTJNUzkzYlhBdlpUazJNVFJqTmpVdE16UTJPQzAwTURBMUxXSmxZVEl0TkRJeVlqaGpZelEyWVRNM0luMC5NVmRmV0xQN0ZpUmNmdjhMSkJCdXJjQS1aUFdJam1lMnd0Y182Vl8yVjU5Q250Z0d0UnFoMHhDaVJoeU9sYjFIcFkzRjZ2MHZvTE84YkVwUU9KT01GUSIsInR5cGUiOiJkaWQifV0sImlzcyI6IndzOi8vaHR0cDovL2xvY2FsaG9zdDo1Njc4L2FwaS92MS93bXAvZTk2MTRjNjUtMzQ2OC00MDA1LWJlYTItNDIyYjhjYzQ2YTM3IiwiaXNzdWVyX3VybCI6Imh0dHA6Ly9sb2NhbGhvc3Q6NTY3OC9hcGkvdjEvaXNzdWVyL2U5NjE0YzY1LTM0NjgtNDAwNS1iZWEyLTQyMmI4Y2M0NmEzNyIsIm5hbWUiOiJ0ZXN0LXdhbGxldCJ9.VGsqBqARbz1d45SpL2Qc2ZLzaZZ3ACWKp63MfLbtkbQ-vUYDo6I4e2d1FaOMTvAS7pG5TaKiFRiiNS13sNJh6A
```
Here is the decoded token header:
```
{
  "alg": "ES256",
  "jwk": {
    "crv": "P-256",
    "kty": "EC",
    "x": "ZCxAyldWT7bLzYB9PiuSu0SDbKtVYvt-cqgneoh4vvw",
    "y": "FgznAd76v49x8HgST76gLqPRWrRSKPa07d0dQAqdoG4"
  },
  "typ": "jwt+wmp/id_token"
}
```
Here is the decoded token payload:
```
{
  "authorization_url": "http://localhost:5678/api/v1/auth/4e0583fe-5ae0-4623-8328-37a6143b36dd",
  "entity_types": [
    "holder",
    "issuer"
  ],
  "iat": 1760820693,
  "identifiers": [
    {
      "identifier": [
        "did:key:z2dmzD81cgPx8Vki7JbuuMmFYrWPgYoytykUZ3eyqht1j9KbqfP8PC5rxKQNVsWdUfonBBcEisrMdFZ8iAMi9FLEFnWmKZamRQioiqxc7KRwYDbTMgvfJN6gcoB4XM6R83whvnb7kehnCEDCr5ce6FSdehHd1uBYSZTrGsN5tmDuDciBzL"
      ],
      "proof": "eyJhbGciOiJFUzI1NiIsImp3ayI6eyJjcnYiOiJQLTI1NiIsImt0eSI6IkVDIiwieCI6IlpDeEF5bGRXVDdiTHpZQjlQaXVTdTBTRGJLdFZZdnQtY3FnbmVvaDR2dnciLCJ5IjoiRmd6bkFkNzZ2NDl4OEhnU1Q3NmdMcVBSV3JSU0tQYTA3ZDBkUUFxZG9HNCJ9LCJ0eXAiOiJqd3Qrd21wL2VudGl0eS1pZC1wcm9vZiJ9.eyJpYXQiOjE3NjA4MjA2OTMsImlzcyI6Imh0dHA6Ly9sb2NhbGhvc3Q6NTY3OC9hcGkvdjEvd21wLzRlMDU4M2ZlLTVhZTAtNDYyMy04MzI4LTM3YTYxNDNiMzZkZCJ9.QJ-QItKWSBbF0j9kOZY130AojuDgTtVr8lB8USUr4aQPz8LXZXUl94yS9mLNlRSBGpfYb1xUS3GDsqc49WRj2A",
      "type": "did"
    }
  ],
  "iss": "http://localhost:5678/api/v1/wmp/4e0583fe-5ae0-4623-8328-37a6143b36dd",
  "issuer_url": "http://localhost:5678/api/v1/issuer/4e0583fe-5ae0-4623-8328-37a6143b36dd",
  "name": "test-wallet"
}
```


### Credential offer
Credential offer message is sent from an entity with `issuer` wallet type to an entity with `holder` wallet type. It's header `typ` claim shall be set to `jwt+wmp/credential_offer`.
The payload shall contain the following claims:
- `offer_url`: An OIDC4VCI Credential Offer URL

Upon receiving a credential offer message, the recipient shall process it using flows specified in OIDC4VCI.

### Credential verification request
Credential verification request is sent from an entity with `verifier` wallet type to an entity with `holder` wallet type. It's header `typ` claim shall be set to `jwt+wmp/credential_verification_request`.
The payload shall contain the following claims:
- `verification_request_url`: An OIDC4VP Credential Verification Request URL

## Verifying WMP messages
All WMP messages are JWT tokens and before any other verification, their signature should be verified. Both `client` and `server` antities must also verify if the message signature is using the same key as the key the entity used during the invitation process.
### Verifying invitations
Before establishing any websocket connection with the server, the client must verify the validity of the JWT signature. If the invitation endpoint is protected by a hashlink, it must also verify whether the hashlink matches the HTTP response body.
After establishing a websocket connection, the client must validate the `code_challenge` with the `code_verifier` provided in the client Verification Request sent by the server.

### Verifying client verification response
After validating the JWT signature, the server must verify the values of the sent `nonce` claim. If the claim is not present, or it's value does not match the one sent by the server, the server must not continue communicating through this channel.

### Verifying ID Token
After validating the JWT signature, the entity must verify the `proof` claim in every element of the `identifiers` claims.

## Key rotation
TBD

## Websocket ping & pong
TBD
