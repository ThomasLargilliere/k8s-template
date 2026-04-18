# Django k8s Template

Template minimal pour un projet Django déployé sur Kubernetes.

**Stack :** Python 3.14 · Django 6 · PostgreSQL 17 · Gunicorn · Whitenoise

## Prérequis

- [Docker](https://docs.docker.com/get-docker/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/) connecté à un cluster local ([minikube](https://minikube.sigs.k8s.io/docs/start/), [k3d](https://k3d.io/), [kind](https://kind.sigs.k8s.io/)…)
- [Skaffold](https://skaffold.dev/docs/install/)
- Un ingress controller nginx installé dans le cluster ([guide d'installation](https://kubernetes.github.io/ingress-nginx/deploy/))

---

## Structure

```
k8s/
  base/               # manifests communs (namespace, db, django, ingress, secret)
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

Variables attendues :

| Variable            | Description                     |
|---------------------|---------------------------------|
| `SECRET_KEY`        | Clé secrète Django              |
| `DEBUG`             | `True` ou `False`               |
| `ALLOWED_HOSTS`     | Hosts autorisés (séparés par `,`)|
| `DB_NAME`           | Nom de la base PostgreSQL       |
| `DB_USER`           | Utilisateur PostgreSQL          |
| `DB_PASSWORD`       | Mot de passe PostgreSQL         |
| `DB_HOST`           | Hostname du service db          |
| `DB_PORT`           | Port PostgreSQL (défaut : 5432) |
| `POSTGRES_DB`       | Utilisé par l'image postgres    |
| `POSTGRES_USER`     | Utilisé par l'image postgres    |
| `POSTGRES_PASSWORD` | Utilisé par l'image postgres    |

### `k8s/base/ingress.yaml`

L'URL par défaut est `myapp.local`. Pour la changer, modifier le champ `host` dans ce fichier, puis mettre à jour `/etc/hosts` en conséquence.

### `skaffold.yaml`

Le nom d'image par défaut est `myapp` (sans registry). Avec `push: false`, Skaffold construit l'image localement et l'injecte directement dans le cluster — **aucun registry nécessaire** pour le développement.

---

## 3. Gitignorer ces fichiers dans ton projet

Ces fichiers contiennent des valeurs spécifiques à ton déploiement. Ajouter dans ton `.gitignore` :

```
k8s/base/secret.yaml
k8s/base/ingress.yaml
skaffold.yaml
```

---

## 4. Lancer en développement

```bash
make dev
```

Skaffold construit l'image, applique l'overlay `dev` (via Kustomize) et surveille les changements.

---

## 5. Accéder à l'application

Ajouter l'entrée dans `/etc/hosts` (`make init` te l'indique automatiquement) :

```bash
echo "127.0.0.1 myapp.local" | sudo tee -a /etc/hosts
```

Puis ouvrir : **http://myapp.local/admin/**

---

## Commandes utiles

```bash
make dev     # démarrage avec hot-reload (Skaffold, overlay dev)
make up      # déploiement prod statique (kubectl apply -k overlays/prod)
make down    # scale tous les deployments à 0
make reset   # supprime le namespace entier
make build   # build + push + mise à jour du tag dans les manifests
```

## En production

Éditer `IMAGE` dans le `Makefile` avec l'URL de ton registry, puis :

```bash
make build   # build + push + mise à jour du tag dans k8s/base/django/
make up      # applique l'overlay prod
```
