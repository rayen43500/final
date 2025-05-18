# API de Statistiques de Tests

Cette API permet de gérer les statistiques des tests exécutés dans l'application. Elle permet de créer, lire, mettre à jour et supprimer des statistiques, ainsi que de générer des rapports agrégés et de comparer les performances entre différentes périodes.

## Base URL

```
/api/statistics
```

## Endpoints

### Créer une statistique de test

```
POST /api/statistics/tests
```

#### Requête

| Paramètre     | Type     | Description                                        | Requis |
|---------------|----------|----------------------------------------------------|--------|
| testName      | String   | Nom du test                                        | Oui    |
| testType      | String   | Type de test (Performance, Fonctionnel, etc.)      | Oui    |
| duration      | Number   | Durée du test en millisecondes                     | Oui    |
| success       | Boolean  | Indique si le test a réussi ou échoué              | Oui    |
| errorCount    | Number   | Nombre d'erreurs rencontrées                       | Non    |
| warningCount  | Number   | Nombre d'avertissements rencontrés                 | Non    |
| module        | String   | Module testé                                       | Oui    |
| environment   | String   | Environnement (Développement, Test, etc.)          | Non    |
| executedBy    | ObjectId | ID de l'utilisateur qui a exécuté le test          | Non    |
| details       | Object   | Détails supplémentaires du test                    | Non    |
| notes         | String   | Notes sur le test                                  | Non    |

#### Réponse

```json
{
  "success": true,
  "data": {
    "_id": "60a5c4e1b27e7a001cf5d6d5",
    "testName": "Test connexion utilisateur",
    "testType": "Fonctionnel",
    "duration": 1245,
    "success": true,
    "errorCount": 0,
    "warningCount": 0,
    "module": "Authentification",
    "environment": "Développement",
    "executedBy": "60a5c4e1b27e7a001cf5d6d6",
    "details": {
      "browser": "Chrome",
      "os": "Windows",
      "resolution": "1920x1080"
    },
    "notes": "Test réussi",
    "createdAt": "2023-06-08T12:34:56Z",
    "updatedAt": "2023-06-08T12:34:56Z"
  }
}
```

### Récupérer toutes les statistiques

```
GET /api/statistics/tests
```

#### Paramètres de requête

| Paramètre   | Type     | Description                                   | Défaut            |
|-------------|----------|-----------------------------------------------|-------------------|
| testName    | String   | Filtrer par nom de test                       | -                 |
| testType    | String   | Filtrer par type de test                      | -                 |
| module      | String   | Filtrer par module                            | -                 |
| environment | String   | Filtrer par environnement                     | -                 |
| success     | Boolean  | Filtrer par succès/échec                      | -                 |
| startDate   | Date     | Date de début pour le filtrage                | -                 |
| endDate     | Date     | Date de fin pour le filtrage                  | -                 |
| sort        | String   | Champ de tri (préfixer par - pour descendant) | -executionDate    |
| limit       | Number   | Nombre d'éléments par page                    | 50                |
| page        | Number   | Numéro de page                                | 1                 |

#### Réponse

```json
{
  "success": true,
  "count": 10,
  "total": 120,
  "totalPages": 12,
  "currentPage": 1,
  "data": [
    {
      "_id": "60a5c4e1b27e7a001cf5d6d5",
      "testName": "Test connexion utilisateur",
      "testType": "Fonctionnel",
      "executionDate": "2023-06-08T12:34:56Z",
      "duration": 1245,
      "success": true,
      "errorCount": 0,
      "warningCount": 0,
      "module": "Authentification",
      "environment": "Développement",
      "executedBy": {
        "_id": "60a5c4e1b27e7a001cf5d6d6",
        "nom": "John Doe",
        "email": "john@example.com"
      },
      "createdAt": "2023-06-08T12:34:56Z",
      "updatedAt": "2023-06-08T12:34:56Z"
    },
    // ...autres statistiques
  ]
}
```

### Récupérer une statistique spécifique

```
GET /api/statistics/tests/:id
```

#### Réponse

```json
{
  "success": true,
  "data": {
    "_id": "60a5c4e1b27e7a001cf5d6d5",
    "testName": "Test connexion utilisateur",
    "testType": "Fonctionnel",
    "executionDate": "2023-06-08T12:34:56Z",
    "duration": 1245,
    "success": true,
    "errorCount": 0,
    "warningCount": 0,
    "module": "Authentification",
    "environment": "Développement",
    "executedBy": {
      "_id": "60a5c4e1b27e7a001cf5d6d6",
      "nom": "John Doe",
      "email": "john@example.com"
    },
    "details": {
      "browser": "Chrome",
      "os": "Windows",
      "resolution": "1920x1080"
    },
    "notes": "Test réussi",
    "createdAt": "2023-06-08T12:34:56Z",
    "updatedAt": "2023-06-08T12:34:56Z"
  }
}
```

### Mettre à jour une statistique

```
PUT /api/statistics/tests/:id
```

#### Requête

Mêmes paramètres que pour la création, mais tous sont optionnels.

#### Réponse

```json
{
  "success": true,
  "data": {
    "_id": "60a5c4e1b27e7a001cf5d6d5",
    "testName": "Test connexion utilisateur (modifié)",
    "testType": "Fonctionnel",
    "duration": 1245,
    "success": true,
    "errorCount": 0,
    "warningCount": 0,
    "module": "Authentification",
    "environment": "Développement",
    "executedBy": "60a5c4e1b27e7a001cf5d6d6",
    "details": {
      "browser": "Chrome",
      "os": "Windows",
      "resolution": "1920x1080"
    },
    "notes": "Test réussi avec modification",
    "createdAt": "2023-06-08T12:34:56Z",
    "updatedAt": "2023-06-08T13:00:00Z"
  }
}
```

### Supprimer une statistique

```
DELETE /api/statistics/tests/:id
```

#### Réponse

```json
{
  "success": true,
  "message": "Statistique de test supprimée avec succès"
}
```

### Obtenir des rapports agrégés

```
GET /api/statistics/reports
```

#### Paramètres de requête

| Paramètre | Type   | Description                                                                                                | Défaut    |
|-----------|--------|-----------------------------------------------------------------------------------------------------------|-----------|
| module    | String | Filtrer par module                                                                                         | -         |
| startDate | Date   | Date de début pour le filtrage                                                                             | -         |
| endDate   | Date   | Date de fin pour le filtrage                                                                               | -         |
| groupBy   | String | Champ de regroupement (testName, testType, module, environment, daily, weekly, monthly)                    | testName  |

#### Réponse

```json
{
  "success": true,
  "count": 5,
  "data": [
    {
      "name": "Test connexion utilisateur",
      "count": 50,
      "successCount": 45,
      "failureCount": 5,
      "successRate": 90.0,
      "avgDuration": 1245.5,
      "totalDuration": 62275,
      "totalErrors": 10,
      "totalWarnings": 15
    },
    // ...autres rapports
  ]
}
```

### Comparer les performances entre deux périodes

```
GET /api/statistics/compare
```

#### Paramètres de requête

| Paramètre         | Type   | Description                       | Requis |
|-------------------|--------|-----------------------------------|--------|
| testName          | String | Filtrer par nom de test           | Non    |
| module            | String | Filtrer par module                | Non    |
| firstPeriodStart  | Date   | Date de début de la première période | Oui    |
| firstPeriodEnd    | Date   | Date de fin de la première période   | Oui    |
| secondPeriodStart | Date   | Date de début de la seconde période  | Oui    |
| secondPeriodEnd   | Date   | Date de fin de la seconde période    | Oui    |

#### Réponse

```json
{
  "success": true,
  "firstPeriod": {
    "start": "2023-05-01",
    "end": "2023-05-31"
  },
  "secondPeriod": {
    "start": "2023-06-01",
    "end": "2023-06-30"
  },
  "comparison": [
    {
      "name": "Test connexion utilisateur",
      "firstPeriod": {
        "count": 30,
        "successRate": 85.0,
        "avgDuration": 1300.5,
        "totalErrors": 8
      },
      "secondPeriod": {
        "count": 25,
        "successRate": 92.0,
        "avgDuration": 1100.2,
        "totalErrors": 4
      },
      "changes": {
        "countChange": -5,
        "successRateChange": 7.0,
        "durationChange": -200.3,
        "errorChange": -4
      }
    },
    // ...autres comparaisons
  ]
}
```

## Codes d'erreur

| Code | Description                                            |
|------|--------------------------------------------------------|
| 400  | Requête invalide (paramètres manquants ou incorrects)  |
| 401  | Non authentifié                                        |
| 403  | Accès non autorisé                                     |
| 404  | Ressource non trouvée                                  |
| 500  | Erreur serveur                                         |

## Exemple d'utilisation

### Créer une statistique de test

```javascript
fetch('/api/statistics/tests', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer YOUR_TOKEN'
  },
  body: JSON.stringify({
    testName: 'Test connexion utilisateur',
    testType: 'Fonctionnel',
    duration: 1245,
    success: true,
    errorCount: 0,
    warningCount: 0,
    module: 'Authentification',
    environment: 'Développement'
  })
})
.then(response => response.json())
.then(data => console.log(data))
.catch(error => console.error('Error:', error));
```

### Récupérer les statistiques filtrées

```javascript
fetch('/api/statistics/tests?module=Authentification&success=true&startDate=2023-06-01&endDate=2023-06-30', {
  method: 'GET',
  headers: {
    'Authorization': 'Bearer YOUR_TOKEN'
  }
})
.then(response => response.json())
.then(data => console.log(data))
.catch(error => console.error('Error:', error));
``` 