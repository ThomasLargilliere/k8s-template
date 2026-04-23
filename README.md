# Django + Vue k8s Template

Template minimal pour un projet Django + Vue déployé sur Kubernetes.

**Stack :** Python 3.14 · Django 6 · Vue 3 · Vite · PostgreSQL 17 · Gunicorn · Whitenoise · nginx

## Prérequis

- [Docker](https://docs.docker.com/get-docker/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/) connecté à un cluster local ([minikube](https://minikube.sigs.k8s.io/docs/start/), [k3d](https://k3d.io/), [kind](https://kind.sigs.k8s.io/)…)
- [Skaffold](https://skaffold.dev/docs/install/)
- [kubeseal](https://github.com/bitnami-labs/sealed-secrets#kubeseal) si tu veux générer des Sealed Secrets
- Un ingress controller nginx installé dans le cluster ([guide d'installation](https://kubernetes.github.io/ingress-nginx/deploy/))

---

## Structure

```
django/               # backend Django (Dockerfile, manage.py, config/)
vue/                  # frontend Vue (Vite + nginx)
k8s/
  base/               # manifests communs (namespace, postgres, django, vue, ingress, secret)
  overlays/
    dev/              # replicas=1, imagePullPolicy=IfNotPresent
    prod/             # replicas=2, imagePullPolicy=Always
```

Les overlays utilisent [Kustomize](https://kustomize.io/) (intégré à kubectl).

---

## 1. Cloner et initialiser

```bash
git clone <url> mon-projet
cd mon-projet
make init NAME=mon-projet
```

`make init` remplace le placeholder `myapp` dans tous les fichiers, vérifie la présence du nginx ingress controller, et indique quoi ajouter dans `/etc/hosts`.

---

## 2. Personnaliser les fichiers de configuration

### `k8s/base/secret.yaml`

Renseigner les identifiants de la base de données et la `SECRET_KEY`.

Ce fichier est uniquement une source locale pour générer les Sealed Secrets. Il n'est pas déployé directement.

Variables attendues :

| Variable            | Description                     |
|---------------------|---------------------------------|
| `SECRET_KEY`        | Clé secrète Django              |
| `DEBUG`             | `True` ou `False`               |
| `ALLOWED_HOSTS`     | Hosts autorisés (séparés par `,`)|
| `DB_NAME`           | Nom de la base PostgreSQL       |
| `DB_USER`           | Utilisateur PostgreSQL          |
| `DB_PASSWORD`       | Mot de passe PostgreSQL         |
| `DB_HOST`           | Hostname du service postgres    |
| `DB_PORT`           | Port PostgreSQL (défaut : 5432) |
| `POSTGRES_DB`       | Utilisé par l'image postgres    |
| `POSTGRES_USER`     | Utilisé par l'image postgres    |
| `POSTGRES_PASSWORD` | Utilisé par l'image postgres    |

### `k8s/base/ingress.yaml`

L'URL par défaut est `myapp.local`. Pour la changer, modifier le champ `host` dans ce fichier, puis mettre à jour `/etc/hosts` en conséquence.

### `skaffold.yaml`

Les noms d'images par défaut sont `myapp-django` et `myapp-vue` (sans registry). Avec `push: false`, Skaffold construit les images localement et les injecte directement dans le cluster — **aucun registry nécessaire** pour le développement.

---

## 3. Gérer les secrets

Le template utilise uniquement les `sealed-secret.yaml` dans les overlays. Le fichier `k8s/base/secret.yaml` sert uniquement à :

- garder les vraies valeurs localement
- générer un `sealed-secret.yaml` par environnement avec `make seal`

Exemples :

```bash
make seal
make seal ENV=prod
```

Cela écrit :

- `k8s/overlays/dev/sealed-secret.yaml`
- `k8s/overlays/prod/sealed-secret.yaml`

Ces fichiers sont ceux utilisés par Kustomize au déploiement.

## 4. Gitignorer ces fichiers dans ton projet

Ces fichiers contiennent des valeurs spécifiques à ton déploiement. Ajouter dans ton `.gitignore` :

```
k8s/base/secret.yaml
k8s/base/ingress.yaml
skaffold.yaml
```

---

## 5. Lancer en développement

```bash
make dev
```

Si `k8s/overlays/dev/sealed-secret.yaml` n'existe pas encore, commencer par :

```bash
make seal
```

Au premier lancement, Skaffold construit les images, applique l'overlay `dev` (via Kustomize), puis synchronise les fichiers sans rebuild pour la majorité des changements:

- Django: sync des `.py`, templates et fichiers `static/`
- Vue: sync de `src/`, `public/`, `index.html` et `vite.config.js`

En dev, Django tourne avec `runserver` et Vue avec le serveur Vite dans le pod pour garder une boucle de feedback rapide.

Les migrations ne sont pas lancées automatiquement en dev. Les exécuter au besoin avec :

```bash
kubectl exec -it -n myapp deploy/django -- python manage.py migrate
```

---

## 6. Accéder à l'application

Ajouter l'entrée dans `/etc/hosts` (`make init` te l'indique automatiquement) :

```bash
echo "127.0.0.1 myapp.local" | sudo tee -a /etc/hosts
```

Puis ouvrir :

- **http://myapp.local/** pour le frontend Vue
- **http://myapp.local/admin/** pour Django admin

---

## Commandes utiles

```bash
make dev     # démarrage avec hot-reload (Skaffold, overlay dev)
make up      # déploiement prod statique (kubectl apply -k overlays/prod)
make down    # scale tous les deployments à 0
make reset   # supprime le namespace entier
make seal    # génère k8s/overlays/<env>/sealed-secret.yaml
make migrate # lance les migrations Django dans le pod en cours
make build   # build + push des images django/vue + mise à jour des tags
make shell   # ouvre un shell dans le pod django en cours d'exécution
```

## En production

Éditer `BACKEND_IMAGE` et `FRONTEND_IMAGE` dans le `Makefile` avec l'URL de ton registry, puis :

```bash
make seal ENV=prod
make build   # build + push + mise à jour des tags dans k8s/base/django/ et k8s/base/vue/
make up ENV=prod  # applique l'overlay prod
```

## Commandes npm utiles

Si tu veux recréer le frontend à la main plutôt que garder le scaffold déjà ajouté :

```bash
npm create vite@latest vue -- --template vue
cd vue
npm install
npm run dev
npm run build
```
