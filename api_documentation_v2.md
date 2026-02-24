# CEMDO Mobile API V2 Documentation

Base URL: `https://api.cemdo.com.ar` (or specific environment URL)
Prefix: `/api/v2`

## Headers
All requests should include:
- `Accept: application/json`
- `Content-Type: application/json`

Authenticated requests must include:
- `Authorization: Bearer <token>`

---

## Authentication

### Login
**POST** `/api/v2/login`

Returns an access token for the user.

**Body:**
```json
{
  "email": "usuario@ejemplo.com",
  "password": "password123",
  "device_name": "Samsung S21" // Required to identify the token
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "token": "13|AbCdEfGhIjKlMnOpQrStUvWxMz...",
    "user": {
      "id": 1,
      "name": "Juan Perez",
      "email": "usuario@ejemplo.com",
      "ultimo_idcliente": 1001,
      ...
    }
  },
  "message": "Login exitoso"
}
```

### Logout
**POST** `/api/v2/logout`

Revokes the current access token and removes the associated device token.

**Body:**
```json
{
  "device_id": "unique_device_id_abcdef" // Required to cleanup FCM tokens
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Sesión cerrada correctamente"
}
```

### Google Login
**POST** `/api/v2/auth/google/callback`

Authenticates a user via Google ID token.

**Body:**
```json
{
  "id_token": "eyJhbGciOiJSUzI1NiIsImtpZCI6Ij...",
  "device_name": "Pixel 6"
}
```

---

## User

### Get Profile
**GET** `/api/v2/user`

Returns the currently authenticated user.

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "Juan Perez",
    "email": "juan@example.com",
    "ultimo_idcliente": 1001,
    ...
  }
}
```

### Register Device Token (FCM)
**POST** `/api/v2/fcm-token`

Registers a Firebase Cloud Messaging token for push notifications.

**Body:**
```json
{
  "fcm_token": "f5kLM...",
  "device_id": "unique_device_id_abcdef",
  "device_name": "Samsung S21",
  "app_version": "2.0.0"
}
```

---

## Services (Suministros)

### List Services
**GET** `/api/v2/services`

Returns a list of services grouped by type. The supplies within each service are refined to return only essential fields.

**Response (200 OK):**
```json
{
  "data": [
    {
      "id": 1,
      "label": "Energia",
      "tag": "E",
      "supplies": [
        {
          "idsuministro": 1001,
          "categoria": "Residencial",
          "domicilio": "MZ.108 LOTE 15...",
          "localidad": "Villa Dolores",
          "estado": "NORMAL"
        }
      ]
    },
    ...
  ]
}
```

---

### Get Service Details
**GET** `/api/v2/services/{id}`

Returns detailed information based on the service type (`idtipo_srv`).

**Authentication:** Required (Bearer token)

**Path Parameters:**
- `id` (integer, required): The `idsuministro` of the supply to retrieve

**Response Structures:**

#### A. Energy (1), Water (2), and Unificado (99)
Includes technical data, coordinates, and historical consumption.

```json
{
  "data": {
    "idsuministro": 385178,
    "categoria": "Residencial",
    "domicilio": "MZ.108 LOTE 15...",
    "localidad": "VILLA DOLORES",
    "estado": "NORMAL",
    "coordenadas": {
      "latitud": -31.94,
      "longitud": -65.18
    },
    "medidor": {
      "marca": "...",
      "modelo": "...",
      "numero": "..."
    },
    "consumos": {
      "2024": [...],
      "2025": [...]
    }
  }
}
```

#### B. Sepelios (3)
Includes family group information and social service status summary.

```json
{
  "data": {
    "idsuministro": 303126,
    "categoria": "Sepelios",
    "domicilio": "...",
    "grupo_familiar": [
      {
        "id": 1,
        "apellido": "Perez",
        "nombre": "Juan",
        "parentesco": "Titular",
        "3010": "HABILITADO",
        "3210": "HABILITADO",
        "3310": "INHABILITADO"
      }
    ],
    "habilitados": {
      "sepelio": true,
      "ambulancia": true,
      "enfermeria": false
    }
  }
}
```

---

### Technical Notes

1. **Service ID Mapping**:
    - `1`: Energía
    - `2`: Agua
    - `3`: Sepelios
    - `99`: Unificado (Mixed Energy and Water data)

2. **Conditional Logic**:
   - Technical data (`medidor`, `coordenadas`, `consumos`) is only served for types **1, 2, and 99**.
   - Social data (`grupo_familiar`, `habilitados`) is only served for type **3**.

3. **Coordinates Logic**:
   - `coordenadas` object groups `latitud` and `longitud`.
   - Fetched from the GIS database.

4. **Consumption Logic**:
   - Grouped by year for easier front-end processing.
   - Includes data for the current year and the two previous years.

**Example Usage (Flutter/Dart):**
```dart
// Check service type for UI rendering
final idTipoSrv = data['idtipo_srv']; 

if (idTipoSrv == 1 || idTipoSrv == 2 || idTipoSrv == 99) {
  // Render technical details (Map, Meter, Charts)
  final coords = data['coordenadas'];
  final historicalData = data['consumos'];
} else if (idTipoSrv == 3) {
  // Render social details (Family Group, Status summary)
  final family = data['grupo_familiar'];
  final enabled = data['habilitados'];
}
```

---

## Accounts (Cuentas/Clientes)

### List Linked Accounts
**GET** `/api/v2/accounts`

Returns all client accounts linked to the user.

**Response (200 OK):**
```json
{
  "data": [
    {
      "idcliente": 1001,
      "razon_social": "Juan Perez"
    },
    ...
  ]
}
```

### Link Account
**POST** `/api/v2/accounts/link`

Links a new client account to the user.

**Body:**
```json
{
  "nro_usuario": 1001,
  "cuenta_agrupada": 123456, // From paper bill
  "device_id": "optional_device_id",
  "fcm_token": "optional_fcm_token"
}
```

### Unlink Account
**POST** `/api/v2/accounts/unlink`

Removes a linked account.

**Body:**
```json
{
  "cuenta_activa": 1001
}
```

### Change Active Account
**POST** `/api/v2/accounts/change-active`

Updates the user's `ultimo_idcliente` (active context).

**Body:**
```json
{
  "cuenta_activa": 1001
}
```

---

## Invoices (Facturas)

### List All Invoices
**GET** `/api/v2/invoices`

Returns a paginated list of invoices for the active account.

**Parameters:**
- `page`: Page number (default 1)

### List Unpaid Invoices
**GET** `/api/v2/invoices/unpaid`

Returns only unpaid invoices.

### Get PDF
**GET** `/api/v2/pdf/{comprobante}`

Returns the PDF stream for a specific invoice/receipt.

---

## Miscellaneous

### App Version Check
**GET** `/api/v2/app-version`

Returns the minimum required app version.

**Response (200 OK):**
```json
{
  "min_version": "1.5.0",
  "update_required": true, // Context dependent
  "message": "Una nueva versión está disponible."
}
```
