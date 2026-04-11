# Django k8s Template

Template minimal pour un projet Django déployé sur Kubernetes.

**Stack :** Python 3.14 · Django 6 · MariaDB 11 · Gunicorn · Whitenoise

## Prérequis

- [Docker](https://docs.docker.com/get-docker/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/) connecté à un cluster local ([minikube](https://minikube.sigs.k8s.io/docs/start/), [k3d](https://k3d.io/), [kind](https://kind.sigs.k8s.io/)…)
- [Skaffold](https://skaffold.dev/docs/install/)

---

## 1. Cloner et renommer

```bash
git clone <url> mon-projet
cd mon-projet
```

Remplacer le placeholder `myapp` par le nom du projet dans tous les fichiers :

```bash
grep -rl 'myapp' . | xargs sed -i 's/myapp/mon-projet/g'
```

---

## 2. Personnaliser les fichiers de configuration

Tous les fichiers nécessaires sont déjà présents dans le repo. Il suffit de les adapter.

### `k8s/secret.yaml`

Renseigner les identifiants de la base de données et la `SECRET_KEY`.

### `k8s/ingress.yaml`

Remplacer `myapp.local` par le nom de domaine souhaité.

### `k8s/web/deployment.dev.yaml`

Vérifier que le nom d'image correspond à celui défini dans `skaffold.yaml` (par défaut `myapp`).

### `skaffold.yaml`

Le nom d'image par défaut est `myapp` (sans registry). Avec `push: false`, Skaffold construit l'image localement et l'injecte directement dans le cluster — **aucun registry nécessaire** pour le développement.

---

## 3. Gitignorer ces fichiers dans ton projet

Ces fichiers contiennent des valeurs spécifiques à ton déploiement. Ajouter dans ton `.gitignore` :

```
k8s/secret.yaml
k8s/ingress.yaml
k8s/web/deployment.dev.yaml
skaffold.yaml
```

---

## 4. Lancer en développement

```bash
make dev
```

Skaffold construit l'image, applique les manifests et surveille les changements.

---

## 5. Accéder à l'application

Ajouter l'entrée dans `/etc/hosts` :

```bash
echo "127.0.0.1 myapp.local" | sudo tee -a /etc/hosts
```

Puis ouvrir : **http://myapp.local/admin/**

---

## Commandes utiles

```bash
make dev     # démarrage avec hot-reload (Skaffold)
make up      # déploiement statique (kubectl apply)
make down    # scale tous les deployments à 0
make reset   # supprime le namespace entier
```

## En production

Éditer `IMAGE` dans le `Makefile` avec l'URL de ton registry, puis :

```bash
make build   # build + push + mise à jour du tag dans les manifests
```
