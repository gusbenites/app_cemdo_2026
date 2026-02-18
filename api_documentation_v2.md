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

Returns a list of services (Energy, Water, etc.) grouped by type, containing their associated supplies.

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
          "nrosum": 12345,
          "nroorden": 1,
          "direccion": "San Martin 450",
          "localidad": "Villa Dolores",
          "estado": "Conectado",
          "estado_id": 1,
          "categoria": "Residencial"
        }
      ]
    },
    {
      "id": 2,
      "label": "Agua",
      "tag": "A",
      "supplies": [...]
    }
  ]
}
  ]
}
```

### Get Service Details
**GET** `/api/v2/services/{id}`

Returns detailed information about a specific supply (suministro), including meter data, consumption history, and geographic coordinates when available.

**Authentication:** Required (Bearer token)

**Path Parameters:**
- `id` (integer, required): The `idsuministro` of the supply to retrieve

**Authorization:**
- The supply must belong to one of the authenticated user's linked client accounts
- Returns `404 Not Found` if the supply doesn't exist or doesn't belong to the user

**Response (200 OK):**
```json
{
  "data": {
    "idsuministro": 1001,
    "nrosum": 12345,
    "nroorden": 1,
    "direccion": "San Martin 450, Villa Dolores, Cordoba",
    "localidad": "Villa Dolores",
    "estado": "Conectado",
    "estado_id": 1,
    "categoria": "Residencial",
    "latitud": -31.945,
    "longitud": -65.18,
    "medidor": {
      "id": 555,
      "nro_serie": "987654321",
      "modelo": "Monofasico",
      "marca": "Hexing",
      "tipo": "Digital",
      "estado": "Activo"
    },
    "consumos_historicos": {
      "2023": [
        {
          "periodo": 1,
          "anio": 2023,
          "consumo": 250.5
        },
        {
          "periodo": 2,
          "anio": 2023,
          "consumo": 280.0
        }
      ],
      "2024": [
        {
          "periodo": 1,
          "anio": 2024,
          "consumo": 300.0
        }
      ]
    }
  }
}
```

**Important Notes:**

1. **Coordinates (latitud/longitud)**:
   - Only available for **Energy** services (`idtipo_srv = 1`)
   - Will be `null` for other service types (Water, Gas, Internet, etc.)
   - Sourced from a separate GIS database with PostGIS geometry data

2. **Meter Data (medidor)**:
   - May be `null` if the supply doesn't have an associated meter
   - Common for non-energy services

3. **Consumption History (consumos_historicos)**:
   - Available for both **Energy** and **Water** services
   - Organized by year, then by period (month)
   - `periodo`: 1-12 representing the month
   - `consumo`: Numeric value in kWh (energy) or m³ (water)
   - May be an empty object `{}` if no consumption data exists

4. **For Chart Rendering**:
   - Each year contains an array of 1-12 consumption records
   - Sort by `periodo` to display Jan-Dec chronologically
   - Handle missing periods (some months may not have data)
   - Compare multiple years by iterating over the year keys

**Error Responses:**

**401 Unauthorized:**
```json
{
  "message": "Unauthenticated."
}
```

**404 Not Found:**
```json
{
  "message": "No query results for model [App\\Models\\Suministro]"
}
```
Returned when:
- The supply ID doesn't exist
- The supply doesn't belong to any of the user's linked accounts

**Example Usage (Flutter/Dart):**
```dart
// Fetch supply details
final response = await dio.get(
  '/api/v2/services/1001',
  options: Options(headers: {'Authorization': 'Bearer $token'})
);

final data = response.data['data'];

// Check if coordinates are available
if (data['latitud'] != null && data['longitud'] != null) {
  // Display map with marker
  showMap(data['latitud'], data['longitud']);
}

// Render consumption chart
final consumos = data['consumos_historicos'];
if (consumos.isNotEmpty) {
  // Extract years for year selector
  final years = consumos.keys.toList();
  
  // Get consumption data for selected year
  final yearData = consumos[selectedYear];
  
  // Prepare chart data
  final chartData = yearData.map((item) => 
    ChartPoint(month: item['periodo'], value: item['consumo'])
  ).toList();
  
  renderChart(chartData);
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
