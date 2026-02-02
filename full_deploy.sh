# #!/bin/bash
# set -e

# # Step 1: Create EKS infrastructure with Terraform
# cd terraform-eks
# terraform init
# terraform apply -auto-approve

# # Step 2: Get cluster name and region from Terraform outputs
# CLUSTER_NAME=$(terraform output -raw cluster_name)
# REGION=$(terraform output -raw region)
# cd ..

# # Step 3: Update kubeconfig using AWS CLI and Terraform outputs
# aws eks --region "$REGION" update-kubeconfig --name "$CLUSTER_NAME"

# # Step 4: Force scale node group to 3 t3.small nodes
# NODEGROUP_NAME=$(aws eks list-nodegroups --cluster-name "$CLUSTER_NAME" --region "$REGION" --query 'nodegroups[0]' --output text)
# aws eks update-nodegroup-config --cluster-name "$CLUSTER_NAME" --nodegroup-name "$NODEGROUP_NAME" --scaling-config minSize=3,maxSize=6,desiredSize=3 --region "$REGION"

# # Step 5: Run all Ansible playbooks in one step
# ansible-playbook ansible-eks/playbooks/deploy_all.yml

# Step 6: Infrastructure checks
echo "==== Kubernetes Resources ===="
echo ""
echo "Nodes:"
kubectl get nodes
echo ""
echo "Pods:"
kubectl get pods -A
echo ""
echo "Services:"
kubectl get svc -A
echo ""
echo "Deployments:"
kubectl get deployments -A
echo ""
echo "Ingresses:"
kubectl get ingress -A
echo ""

# Step 7: Get ALB Hostnames for Ingresses
APP_ALB_HOSTNAME=$(kubectl get ingress app-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' -n default)
GRAFANA_ALB_HOSTNAME=$(kubectl get ingress grafana-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' -n monitoring)

# Step 8: Remind to add hosts entries with correct IPs
APP_ALB_IP=$(dig +short $APP_ALB_HOSTNAME | head -n1)
GRAFANA_ALB_IP=$(dig +short $GRAFANA_ALB_HOSTNAME | head -n1)
echo "==== IMPORTANT ===="
echo "Add these lines to your /etc/hosts file if not already present:"
echo "$APP_ALB_IP frontend.contapics.local"
echo "$APP_ALB_IP backend.contapics.local"
echo "$GRAFANA_ALB_IP grafana.contapics.local"
echo "==================="
echo ""

# Step 9: Provide clickable links for services
echo "Access your services:"
echo "Frontend:  http://frontend.contapics.local"
echo "Backend:   http://backend.contapics.local/api/health"
echo "Grafana:   http://grafana.contapics.local"
echo ""

# Step 10: Provide Grafana admin password
echo "Grafana admin password:"
kubectl get secret --namespace monitoring prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
echo ""

# Step 11: Test endpoints with curl
echo "Testing endpoints..."
curl -s -o /dev/null -w "Frontend HTTP status: %{http_code}\n" -H "Host: frontend.contapics.local" http://$APP_ALB_IP
curl -s -o /dev/null -w "Backend health HTTP status: %{http_code}\n" -H "Host: backend.contapics.local" http://$APP_ALB_IP/api/health
curl -s -o /dev/null -w "Grafana HTTP status: %{http_code}\n" -H "Host: grafana.contapics.local" http://$GRAFANA_ALB_IP
echo ""

echo "Done!"