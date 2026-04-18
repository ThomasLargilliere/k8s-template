IMAGE ?= your-registry/myapp
NAMESPACE ?= myapp

init:
	@[ "$(origin NAME)" = "command line" ] || (echo "Usage: make init NAME=mon-projet"; exit 1)
	@kubectl get ingressclass nginx >/dev/null 2>&1 || \
		echo "ATTENTION : aucun ingress controller nginx detecte dans le cluster. L'application ne sera pas accessible par hostname sans lui."
	grep -rl 'myapp' . --exclude-dir='.git' | xargs sed -i 's/myapp/$(NAME)/g'
	@echo ""
	@echo "Projet initialise : $(NAME)"
	@echo ""
	@echo "Ajoute cette ligne dans /etc/hosts :"
	@echo "  127.0.0.1 $(NAME).local"
	@echo ""
	@echo "Pour changer l'URL, edite : k8s/base/ingress.yaml"

dev:
	skaffold dev --cleanup=false

down:
	kubectl scale deployment --all --replicas=0 -n $(NAMESPACE)

reset:
	kubectl delete namespace $(NAMESPACE)

up:
	kubectl apply -k k8s/overlays/prod

build:
	docker build -t $(IMAGE):$(shell git rev-parse --short HEAD) ./django
	docker push $(IMAGE):$(shell git rev-parse --short HEAD)
	sed -i 's|$(IMAGE):.*|$(IMAGE):$(shell git rev-parse --short HEAD)|g' k8s/base/django/deployment.yaml
	sed -i 's|$(IMAGE):.*|$(IMAGE):$(shell git rev-parse --short HEAD)|g' k8s/base/django/migrate-job.yaml

shell:
	kubectl exec -it -n $(NAMESPACE) \
		$(shell kubectl get pod -n $(NAMESPACE) -l app=django -o jsonpath='{.items[0].metadata.name}') \
		-- /bin/bash
